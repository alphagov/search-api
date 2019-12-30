module LearnToRank::DataPipeline
  class Worker
    include Sidekiq::Worker

    def perform(bigquery_credentials, s3_bucket)
      LearnToRank::DataPipeline.set_status("Fetching analytics data from bigquery...")
      queries = GovukStatsd.time("data_pipeline.bigquery") do
        queries = LearnToRank::DataPipeline::Bigquery.fetch(bigquery_credentials)
        LearnToRank::DataPipeline::LoadSearchQueries.from_bigquery(queries)
      end

      LearnToRank::DataPipeline.set_status("Generating relevancy judgements...")
      relevancy_judgements = GovukStatsd.time("data_pipeline.judgements") do
        LearnToRank::DataPipeline::RelevancyJudgements.new(queries: queries).relevancy_judgements
      end

      LearnToRank::DataPipeline.set_status("Embedding document features...")
      augmented_judgements = GovukStatsd.time("data_pipeline.features") do
        LearnToRank::DataPipeline::EmbedFeatures.new(relevancy_judgements).augmented_judgements
      end

      LearnToRank::DataPipeline.set_status("Generating SVM data...")
      svm = GovukStatsd.time("data_pipeline.svm") do
        raw_svm = LearnToRank::DataPipeline::JudgementsToSvm.new(augmented_judgements).svm_format.group_by { |row| row.split(" ")[1] }
        svm = { train: "", test: "", validate: "" }

        raw_svm.values.shuffle.each.with_index do |query_set, index|
          # 70% in train 20% in test, 10% in validate
          bucket = %i(train train train train train train train test test validate)[index % 10]
          query_set.each do |row|
            svm[bucket] << row
            svm[bucket] << "\n"
          end
        end

        svm
      end

      LearnToRank::DataPipeline.set_status("Uploading to S3...")
      GovukStatsd.time("data_pipeline.upload") do
        now = Time.now.strftime("%Y-%m-%d")
        Aws::S3::Object.new(bucket_name: s3_bucket, key: "data/#{now}/train.txt").put(body: svm[:train])
        Aws::S3::Object.new(bucket_name: s3_bucket, key: "data/#{now}/test.txt").put(body: svm[:test])
        Aws::S3::Object.new(bucket_name: s3_bucket, key: "data/#{now}/validate.txt").put(body: svm[:validate])
      end

      LearnToRank::DataPipeline.set_status(LearnToRank::DataPipeline::READY_STATUS)
    rescue StandardError => e
      LearnToRank::DataPipeline.set_status(LearnToRank::DataPipeline::ERROR_STATUS)
      GovukError.notify(e)
    end
  end
end
