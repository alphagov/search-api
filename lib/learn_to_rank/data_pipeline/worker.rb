require "aws-sdk-s3"
require "tempfile"

module LearnToRank::DataPipeline
  class Worker
    include Sidekiq::Worker

    def perform(bigquery_credentials, s3_bucket)
      now = Time.now.to_i.to_s
      train = Tempfile.new("search-ltr-train")
      test = Tempfile.new("search-ltr-test")
      validate = Tempfile.new("search-ltr-validate")

      LearnToRank::DataPipeline.set_status("Fetching analytics data from bigquery...")
      queries = GovukStatsd.time("data_pipeline.bigquery") do
        LearnToRank::DataPipeline::LoadSearchQueries.from_bigquery(
          LearnToRank::DataPipeline::Bigquery.fetch(bigquery_credentials),
        )
      end

      LearnToRank::DataPipeline.set_status("Generating SVM data...")
      GovukStatsd.time("data_pipeline.generation") do
        svm = LearnToRank::DataPipeline::JudgementsToSvm.new(
          LearnToRank::DataPipeline::EmbedFeatures.new(
            LearnToRank::DataPipeline::RelevancyJudgements.new(queries: queries).relevancy_judgements,
          ).augmented_judgements,
        ).svm_format_grouped_by_query

        # 70% in train 20% in test, 10% in validate
        files = [train, train, train, train, train, train, train, test, test, validate].shuffle

        svm.each_with_index do |query_set, index|
          file = files[index % 10]
          query_set.each { |row| file.puts(row) }
        end

        train.rewind
        test.rewind
        validate.rewind
      end

      LearnToRank::DataPipeline.set_status("Uploading SVM data to S3...")
      GovukStatsd.time("data_pipeline.upload") do
        Aws::S3::Object.new(bucket_name: s3_bucket, key: "data/#{now}/train.txt").put(body: train)
        Aws::S3::Object.new(bucket_name: s3_bucket, key: "data/#{now}/test.txt").put(body: test)
        Aws::S3::Object.new(bucket_name: s3_bucket, key: "data/#{now}/validate.txt").put(body: validate)
      end

      LearnToRank::DataPipeline.set_status(LearnToRank::DataPipeline::READY_STATUS)
      LearnToRank::DataPipeline.set_latest_data(now)
    rescue StandardError => e
      LearnToRank::DataPipeline.set_status(LearnToRank::DataPipeline::ERROR_STATUS)
      GovukError.notify(e)
    ensure
      train.close
      train.unlink
      test.close
      test.unlink
      validate.close
      validate.unlink
    end
  end
end
