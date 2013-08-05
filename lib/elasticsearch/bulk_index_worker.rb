require "sidekiq"
require "sidekiq_json_encoding_patch"
require "failed_job_worker"

module Elasticsearch
  # This class requires the `config.rb` file to be loaded, since it requires
  # access to the `search_config` setting, but including it here can cause a
  # circular require dependency, from:
  #
  #   SearchConfig -> SearchServer -> IndexGroup -> Index -> DocumentQueue ->
  #   BulkIndexWorker -> SearchConfig
  class BulkIndexWorker
    include Sidekiq::Worker
    sidekiq_options :retry => 5, :queue => :bulk, :backtrace => 12

    # Logger is defined on the class for use inthe `sidekiq_retries_exhausted`
    # block, and as an instance method for use the rest of the time
    def self.logger
      Logging.logger[self]
    end

    def logger
      self.class.logger
    end

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
