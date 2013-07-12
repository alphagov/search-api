require "sidekiq"
require "search_config"
require "failed_job_worker"

module Elasticsearch
  class BulkIndexWorker
    include Sidekiq::Worker
    sidekiq_options :retry => 5

    def logger
      Logging.logger[self]
    end

    sidekiq_options :queue => :bulk

    def perform(index_name, document_hashes)
      noun = document_hashes.size > 1 ? "documents" : "document"
      logger.info "Indexing #{document_hashes.size} queued #{noun} into #{index_name}"

      index(index_name).bulk_index(document_hashes)
    end

    sidekiq_retries_exhausted do |msg|
      FailedJobWorker.perform_async(msg)
    end

  private
    def index(index_name)
      SearchConfig.new.search_server.index(index_name)
    end
  end
end
