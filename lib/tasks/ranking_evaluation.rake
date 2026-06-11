require "evaluation/rank_eval"

desc "Check how well the search query performs for a set of relevancy judgements"
task :ranking_evaluation, [:datafile] do |_, args|
  csv = args.datafile || begin
    bucket = ENV["AWS_S3_RELEVANCY_BUCKET_NAME"]
    raise "Missing required AWS_S3_RELEVANCY_BUCKET_NAME envvar" if bucket.nil?

    csv = Tempfile.open(["judgements", ".csv"])
    Services.s3_client.get_object(bucket:, key: "judgements.csv", response_target: csv.path)
    csv.path
  end

  begin
    evaluator = Evaluation::RankEval.new(csv)
    results = evaluator.evaluate

    maxlen = results[:query_scores].map { |query, _| query.length }.max
    results[:query_scores].each do |query, score|
      justified_query = "#{query}:".ljust(maxlen + 1)
      puts "#{justified_query} #{score}"
    end
    puts "---"
    puts "overall score: #{results[:score]}"
  ensure
    if csv.is_a?(Tempfile)
      csv.close
      csv.unlink
    end
  end
end
