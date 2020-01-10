module LearnToRank
  module DataPipeline
    PENDING_STATUS = "Pending".freeze
    READY_STATUS = "Ready".freeze
    ERROR_STATUS = "Error".freeze

    REDIS_NAMESPACE = "search-api-ltr".freeze
    REDIS_EXPIRATION_PERIOD = 60 * 60
    REDIS_STATUS_KEY = "ltr-status".freeze
    REDIS_LATEST_DATA_KEY = "ltr-latest-data".freeze

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
      redis.get(REDIS_STATUS_KEY) || READY_STATUS
    end

    def self.set_status(status)
      redis.setex(REDIS_STATUS_KEY, REDIS_EXPIRATION_PERIOD, status)
    end

    def self.get_latest_data
      redis.get(REDIS_LATEST_DATA_KEY)
    end

    def self.set_latest_data(data)
      redis.set(REDIS_LATEST_DATA_KEY, data)
    end

    def self.redis
      Redis.new(
        host: ENV.fetch("REDIS_HOST", "127.0.0.1"),
        port: ENV.fetch("REDIS_PORT", 6379),
        namespace: REDIS_NAMESPACE,
      )
    end
  end
end
