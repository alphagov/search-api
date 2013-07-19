require "sidekiq"
require "config"
require "sidekiq_json_encoding_patch"
require "failed_job_worker"

module Elasticsearch
  class BulkIndexWorker
    include Sidekiq::Worker
    sidekiq_options :retry => 5

    # Logger is defined on the class for use inthe `sidekiq_retries_exhausted`
    # block, and as an instance method for use the rest of the time
    def self.logger
      Logging.logger[self]
    end

    def logger
      self.class.logger
    end

    sidekiq_options :queue => :bulk

    def perform(index_name, document_hashes)
      noun = document_hashes.size > 1 ? "documents" : "document"
      logger.info "Indexing #{document_hashes.size} queued #{noun} into #{index_name}"

      index(index_name).bulk_index(document_hashes)
    end

    sidekiq_retries_exhausted do |msg|
      logger.warn "Job '#{msg["jid"]}' failed; forwarding to failure queue"
      FailedJobWorker.perform_async(msg)
    end

  private
    def index(index_name)
      settings.search_config.search_server.index(index_name)
    end
  end
end
