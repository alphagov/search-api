require "csv"
require "fileutils"
require "rummager"
require "zip"
require "analytics/popular_queries"
require "analytics/total_query_ctr"
require "relevancy/load_judgements"

namespace :learn_to_rank do
  desc "Export a CSV of relevancy judgements generated from CTR on popular queries"
  task :generate_relevancy_judgements do
    assert_ltr!

    popular_queries = Analytics::PopularQueries.new.queries.first(100).map { |q| q[0] }
    ctrs = Analytics::TotalQueryCtr.new(queries: popular_queries).call
    judgements = LearnToRank::CtrToJudgements.new(ctrs).relevancy_judgements
    export_to_csv(judgements, "click_judgments")
  end

  desc "Export a CSV of SVM-formatted relevancy judgements for training a model"
  task :generate_training_dataset, [:judgements_filepath, :svm_dir] do |_, args|
    assert_ltr!

    svm_dir = args.svm_dir || "tmp/ltr_data"
    FileUtils.mkdir_p svm_dir

    csv = args.judgements_filepath
    judgements_data = Relevancy::LoadJudgements.from_csv(csv)
    judgements = LearnToRank::EmbedFeatures.new(judgements_data).augmented_judgements
    svm = LearnToRank::JudgementsToSvm.new(judgements).svm_format.shuffle
    File.open("#{svm_dir}/train.txt", "wb") do |train|
      File.open("#{svm_dir}/validate.txt", "wb") do |validate|
        File.open("#{svm_dir}/test.txt", "wb") do |test|
          svm.each.with_index do |row, index|
            file = [train, train, validate, test][index % 4]
            file.puts(row)
          end
        end
      end
    end
  end

  namespace :reranker do
    desc "Train a reranker model with relevancy judgements"
    task :train, [:svm_dir, :model_dir] do |_, args|
      assert_ltr!

      model_dir = args.model_dir || "tmp/libsvm"
      svm_dir = args.svm_dir || "tmp/ltr_data"
      sh "env OUTPUT_DIR=#{model_dir} TRAIN=#{svm_dir}/train.txt VALI=#{svm_dir}/validate.txt TEST=#{svm_dir}/test.txt ./ltr_scripts/train.sh"
    end

    desc "Pull learn to rank model from S3"
    task :pull, [:model_filename] do |_, args|
      bucket_name = ENV["AWS_S3_RELEVANCY_BUCKET_NAME"]
      raise "Missing required AWS_S3_RELEVANCY_BUCKET_NAME" if bucket_name.blank?

      raise "Please specify the model filename" if args.model_filename.blank?

      model_filename = args.model_filename

      o = Aws::S3::Object.new(bucket_name: bucket_name, key: "ltr/#{model_filename}")

      model_dir = ENV["TENSORFLOW_MODELS_DIRECTORY"]

      raise "Please specify the Tensorflow models directory" if model_dir.blank?

      tmpdir = Dir.mktmpdir
      begin
        path = "#{tmpdir}/#{model_filename}"
        o.get(response_target: path)

        Zip::File.open(path) do |zip_file|
          zip_file.each do |file|
            file_path = File.join("/#{model_dir}/ltr", file.name)
            puts "Extracting archive to #{file_path} ..."
            zip_file.extract(file, file_path) unless File.exist?(file_path)
          end
        end
      ensure
        FileUtils.remove_entry tmpdir
      end
    end

    desc "Serves a trained model"
    task :serve, [:model_dir] do |_, args|
      assert_ltr!

      model_dir = args.model_dir || "tmp/libsvm"
      sh "env EXPORT_PATH=#{__dir__}/../../#{model_dir} ./ltr_scripts/serve.sh"
    end

    desc "Evaluate search performance using nDCG with and without the model"
    task :evaluate, [:relevancy_judgements] do |_, args|
      assert_ltr!

      csv = args.relevancy_judgements
      rounds = [nil, "relevance:B"]
      results, results_with_model = rounds.map do |ab_test_round|
        judgements = Relevancy::LoadJudgements.from_csv(csv)
        evaluator = Evaluate::Ndcg.new(judgements, ab_test_round)
        evaluator.compute_ndcg
      end

      merged = results.keys.each_with_object({}) do |query, hsh|
        hsh[query] = {
          without: results[query],
          with_model: results_with_model[query],
        }
      end

      maxlen = results.keys.map { |query, _| query.length }.max
      score_maxlen = results.values.map { |score, _| score.to_s.length }.max

      merged.map do |(query, scores)|
        winning = scores[:without] <= scores[:with_model] ? "√" : "x"
        puts "#{winning} #{(query + ':').ljust(maxlen + 1)} #{scores[:without].to_s.ljust(score_maxlen + 1)} #{scores[:with_model]}"
      end

      winning = merged.dig("average_ndcg", :without) <= merged.dig("average_ndcg", :with_model)

      puts "---"
      puts "without model score: #{merged["average_ndcg"][:without]}"
      puts "with model score: #{merged["average_ndcg"][:with_model]}"
      puts "The model has a #{winning ? "good" : "bad"} score"
    end
  end

  def assert_ltr!
    raise "set $ENABLE_LTR to use learn_to_rank" if ENV["ENABLE_LTR"].nil?
  end

  def export_to_csv(hash, filename)
    CSV.open("tmp/#{filename}.csv", "wb") do |csv|
      csv << hash.first.keys
      hash.each do |row|
        csv << row.values
      end
    end
  end
end
