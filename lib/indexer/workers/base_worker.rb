require "sidekiq"
require "airbrake"

module Indexer
  class BaseWorker
    include Sidekiq::Worker

    # How long to wait, by default, if the index is currently locked
    LOCK_DELAY = 60 # seconds

    # Default options: can be overridden with `sidekiq_options` in subclasses
    sidekiq_options retry: 5, backtrace: 12

    def logger
      self.class.logger
    end

    # Logger is defined on the class for use in the `sidekiq_retries_exhausted`
    # block, and as an instance method for use the rest of the time
    def self.logger
      Logging.logger[self]
    end

    def self.notify_of_failures
      sidekiq_retries_exhausted do |msg|
        logger.warn "Job '#{msg["jid"]}' failed"
        Airbrake.notify_or_ignore(Indexer::FailedJobException.new, parameters: msg)
      end
    end

  private

    def index(index_name)
      Rummager.settings.search_config.search_server.index(index_name)
    end
  end
end
