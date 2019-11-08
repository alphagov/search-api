require "csv"
require "rummager"
require "analytics/popular_queries"
require "analytics/total_query_ctr"
require "learn_to_rank/ctr_to_judgements"

namespace :learn_to_rank do
  desc "Export a CSV of relevancy judgements generated from CTR on popular queries"
  task :generate_relevancy_judgements do
    popular_queries = Analytics::PopularQueries.new.queries.first(100).map { |q| q[0] }
    ctrs = Analytics::TotalQueryCtr.new(queries: popular_queries).call
    judgements = LearnToRank::CtrToJudgements.new(ctrs).relevancy_judgements
    export_to_csv(judgements, 'click_judgments')
  end

  desc "Export a CSV of SVM-formatted relevancy judgements for training a model"
  task :generate_training_dataset, [:judgements_filepath] do |_, args|
    csv = args.judgements_filepath
    judgements = LearnToRank::EmbedFeatures.new(csv).augmented_judgements
    svm = LearnToRank::JudgementsToSvm.new(judgements).svm_format.shuffle
    set_size = svm.count / 3
    svm.in_groups_of(set_size).each.with_index do |svm_set, index|
      name = %w(train validate test)[index]
      File.open("tmp/#{name}.txt", "wb") do |file|
        svm_set.each { |row| file.puts(row) }
      end
    end
  end

  desc "Train a reranker model with relevancy judgements"
  task :train_reranker_model, [:svm_dir, :model_dir] do |_, args|
    model_dir = args.model_dir || "tmp/libsvm"
    svm_dir = args.svm_filepath || "tmp/ltr_data"
    sh "env OUTPUT_DIR=#{model_dir} TRAIN=#{svm_dir}/train.txt VALI=#{svm_dir}/validate.txt TEST=#{svm_dir}/test.txt ./ltr_scripts/train.sh"
  end

  desc "Serves a trained model"
  task :serve_reranker_model do
    # TODO
    # - Call with a filepath of a ranked model
    # - Calls serve.sh
    sh " OUTPUT_DIR
    TRAIN
    VALI
    TEST=#{x} ./ltr_scripts/train.sh"
  end

  desc "Evaluate search performance using nDCG with and without the model"
  task :how_is_it_doing do
    # TODO
    # - Call with a CSV arg of relevancy judgements
    # - runs ndcg with and without model ab test
    # - prints them nicely with comparison
    # - says who is winning and by how much
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
