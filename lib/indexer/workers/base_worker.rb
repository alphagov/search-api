module Indexer
  class BaseWorker
    include Sidekiq::Worker

    # How long to wait, by default, if the index is currently locked
    LOCK_DELAY = 60 # seconds

    # Default options: can be overridden with `sidekiq_options` in subclasses
    sidekiq_options retry: 5, backtrace: 12

    def self.notify_of_failures
      sidekiq_retries_exhausted do |msg|
        GovukError.notify(Indexer::FailedJobException.new, extra: msg)
      end
    end

    # Wait for all tasks for the given queue/worker class combination to be
    # completed before continuing
    def self.wait_until_processed(max_timeout: 2 * 60 * 60)
      Timeout.timeout(max_timeout) do
        # wait for all queued tasks to be started
        sleep 1 while Sidekiq::Queue.new(self::QUEUE_NAME).any? { |job| job.display_class == to_s }

        # wait for started tasks to be finished
        sleep 1 while active_workers?
      end
    end

    def self.active_workers?
      Sidekiq::Workers.new.any? do |_, _, work|
        work["queue"] == self::QUEUE_NAME && work["payload"]["class"] == to_s
      end
    end

  private

    def indexes(index_name)
      SearchConfig.search_servers.map do |search_server|
        search_server.index(index_name)
      end
    end
  end
end
