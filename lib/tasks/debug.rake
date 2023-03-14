require "aws-sdk-s3"
require "csv"
require "rummager"
require "rainbow"
require "debug/rank_eval"
require "debug/synonyms"
require "tempfile"

ANSI_GREEN = "\e[32m".freeze
ANSI_RESET = "\e[0m".freeze

namespace :debug do
  desc "Pretty print a document in the old content indexes"
  task :show_old_index_link, [:link] do |_, args|
    index = SearchConfig.default_instance.old_content_index
    docs = index.get_document_by_link(args.link)
    pp docs
  end

  desc "Pretty print a document in the new content index"
  task :show_govuk_link, [:link] do |_, args|
    index = SearchConfig.default_instance.new_content_index
    docs = index.get_document_by_link(args.link)
    pp docs
  end

  desc "New synonyms test"
  task :show_new_synonyms, [:query] do |_, args|
    model = Debug::Synonyms::Analyzer.new

    search_tokens = model.analyze_query(args.query)
    index_tokens = model.analyze_index(args.query)
    search_results = model.search(args.query, pre_tags: [ANSI_GREEN], post_tags: [ANSI_RESET])

    puts Rainbow("Query interpretation for '#{args.query}':").yellow
    puts search_tokens["tokens"]
    puts ""

    puts Rainbow("Document with this exact text is indexed as:").yellow
    puts index_tokens["tokens"]
    puts ""

    puts Rainbow("Sample matches (basic query with synonyms):").yellow

    hits = search_results["hits"]["hits"]
    if hits.empty?
      puts Rainbow("No results found").red
    else
      hits.each do |hit|
        title = hit.dig("highlight", "title.synonym") || hit.dig("_source", "title")
        description = hit.dig("highlight", "description.synonym") || hit.dig("_source", "description")
        puts title
        puts description if description
        puts ""
      end
    end
  end

  desc "Check how well the search query performs for a set of relevancy judgements"
  task :ranking_evaluation, [:datafile, :ab_tests] do |_, args|
    csv = args.datafile || begin
      bucket_name = ENV["AWS_S3_RELEVANCY_BUCKET_NAME"]
      raise "Missing required AWS_S3_RELEVANCY_BUCKET_NAME envvar" if bucket_name.nil?

      csv = Tempfile.open(["judgements", ".csv"])
      o = Aws::S3::Object.new(bucket_name:, key: "judgements.csv")
      o.get(response_target: csv.path)
      csv.path
    end

    begin
      evaluator = Debug::RankEval.new(csv, args.ab_tests)
      results = evaluator.evaluate

      maxlen = results[:query_scores].map { |query, _| query.length }.max
      results[:query_scores].each do |query, score|
        justified_query = "#{query}:".ljust(maxlen + 1)
        puts "#{justified_query} #{score}"
      end
      puts "---"
      puts "overall score: #{results[:score]}"

      if ENV["SEND_TO_GRAPHITE"]
        Services.statsd_client.gauge(
          "relevancy.query.overall_score.rank_eval",
          results[:score],
        )
      end
    ensure
      if csv.is_a?(Tempfile)
        csv.close
        csv.unlink
      end
    end
  end

  desc "Get the best bets which match a query"
  task :fetch_best_bets, [:query] do |_, args|
    metasearch_index = SearchConfig.default_instance.metasearch_index
    bets = Search::BestBetsChecker.new(args[:query], metasearch_index)
    CSV do |out|
      (bets.best_bets || []).each do |position, links|
        links.each { |link| out << ["best", link, position] }
      end
      (bets.worst_bets || []).each do |link|
        out << ["worst", link]
      end
    end
  end
end
