require "rummager"
require "analytics/overall_ctr"
require "analytics/popular_queries"
require "analytics/query_performance"
require "relevancy/load_judgements"

namespace :relevancy do
  desc "Show overall click-through-rate for top 3 results and top 10 results"
  task :show_overall_ctr do
    report_overall_ctr
  end

  desc "Show underperforming queries from top 1_000 most popular queries"
  task :show_underperfoming_queries do
    report_query_ctr
  end

  desc "Print the top 1_000 most popular search queries, their viewcounts and CTR"
  task :show_top_queries do
    puts "Top queries:"
    report_popular_queries
    puts "CTR for top queries:"
    report_query_ctr
  end

  desc "Compute nDCG for a set of relevancy judgements (search performance metric)"
  task :ndcg, [:datafile, :ab_tests] do |_, args|
    report_ndcg(datafile: args.datafile, ab_tests: args.ab_tests)
  end

  desc "Send Google Analytics relevancy data to Graphite
  Takes about 10 minutes.
  Requires SEND_TO_GRAPHITE envvar being set"
  task :send_ga_data_to_graphite do
    puts "Sending overall CTR to graphite"
    report_overall_ctr
    puts "Finished"
  end
end

def report_ndcg(datafile: nil, ab_tests: nil)
  csv = datafile || relevancy_judgements_from_s3
  begin
    judgements = Relevancy::LoadJudgements.from_csv(csv)
    evaluator = Evaluate::Ndcg.new(judgements, ab_tests)
    results = evaluator.compute_ndcg

    maxlen = results.keys.map { |query, _| query.length }.max
    results.map do |(query, score)|
      puts "#{(query + ':').ljust(maxlen + 1)} #{score}"
    end
    puts "---"
    puts "overall score: #{results['average_ndcg']}"
  ensure
    if csv.is_a?(Tempfile)
      file.close
      file.unlink
    end
  end
end

def report_overall_ctr
  report(Analytics::OverallCTR.new.call)
end

def report_query_ctr
  ctrs = Analytics::QueryPerformance.new(queries: popular_queries.map { |q| q[0] }).call
  ctrs.each do |(stat, reading)|
    puts "#{stat.downcase.gsub(' ', '_')}: #{reading}"
  end
end

def report_popular_queries
  puts "Popular queries:"
  popular_queries.map { |(query, viewcount)| puts "#{query}: #{viewcount}" }
end

def popular_queries
  @popular_queries ||= Analytics::PopularQueries.new.queries
end

def report(stats = [])
  puts "STATS (past 7 days):"
  puts "=================="
  stats.each do |(stat, reading)|
    puts "#{stat.downcase.gsub(' ', '_')}: #{reading}"
    send_to_graphite(stat, reading)
  end
end
