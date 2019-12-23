module LearnToRank
  module DataPipeline
    PENDING_STATUS = "Pending".freeze
    READY_STATUS = "Ready".freeze
    ERROR_STATUS = "Error".freeze

    REDIS_EXPIRATION_PERIOD = 60 * 60

    def self.perform_async(bigquery_credentials, s3_bucket)
      # This has a race condition (two 'perform' calls, or a 'perform'
      # call + a 'perform_async' call) could be executed in different
      # processes concurrently, pass the 'can_run?' check, and start
      # the job.
      #
      # Processors solve a similar problem by offering an atomic "test
      # and set" instruction, which does this (but atomically):
      #
      #     byte test_and_set(byte *address, byte old, byte new) {
      #       if (*address == old) { *address = new; }
      #       return *address;
      #     }
      #
      # Redis lacks a "test and set" primitive.
      #
      # Since this task runs only infrequently (usually only once per
      # day, triggered by a single API call), the chances of a race
      # are very rare and so implementing a proper distributed locking
      # algorithm seems overkill.
      if can_run?
        set_status(PENDING_STATUS)
        LearnToRank::DataPipeline::Worker.perform_async(bigquery_credentials, s3_bucket)
        true
      else
        false
      end
    end

    def self.perform_sync(bigquery_credentials, s3_bucket)
      # This has the same race condition as 'perform_async'.
      if can_run?
        set_status(PENDING_STATUS)
        LearnToRank::DataPipeline::Worker.new.perform(bigquery_credentials, s3_bucket)
        true
      else
        false
      end
    end

    def self.can_run?
      [READY_STATUS, ERROR_STATUS].include? get_status
    end

    def self.get_status
      redis = Redis.new(
        host: ENV.fetch("REDIS_HOST", "127.0.0.1"),
        port: ENV.fetch("REDIS_PORT", 6379),
        namespace: "search-api-ltr",
      )
      redis.get("ltr-status") || READY_STATUS
    end

    def self.set_status(status)
      redis = Redis.new(
        host: ENV.fetch("REDIS_HOST", "127.0.0.1"),
        port: ENV.fetch("REDIS_PORT", 6379),
        namespace: "search-api-ltr",
      )
      redis.setex("ltr-status", REDIS_EXPIRATION_PERIOD, status)
    end

    class Worker
      include Sidekiq::Worker

      def perform(bigquery_credentials, s3_bucket)
        LearnToRank::DataPipeline.set_status("Fetching analytics data from bigquery...")
        queries = GovukStatsd.time("data_pipeline.bigquery") do
          LearnToRank::LoadSearchQueries.from_bigquery(LearnToRank::Bigquery.fetch(bigquery_credentials))
        end

        LearnToRank::DataPipeline.set_status("Generating relevancy judgements...")
        relevancy_judgements = GovukStatsd.time("data_pipeline.judgements") do
          LearnToRank::RelevancyJudgements.new(queries: queries).relevancy_judgements
        end

        LearnToRank::DataPipeline.set_status("Embedding document features...")
        augmented_judgements = GovukStatsd.time("data_pipeline.features") do
          LearnToRank::EmbedFeatures.new(relevancy_judgements).augmented_judgements
        end

        LearnToRank::DataPipeline.set_status("Generating SVM data...")
        svm = GovukStatsd.time("data_pipeline.svm") do
          raw_svm = LearnToRank::JudgementsToSvm.new(augmented_judgements).svm_format.group_by { |row| row.split(" ")[1] }
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
end
