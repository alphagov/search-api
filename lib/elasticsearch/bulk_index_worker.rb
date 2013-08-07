require "elasticsearch/base_worker"

module Elasticsearch
  class BulkIndexWorker < BaseWorker
    forward_to_failure_queue

    def perform(index_name, document_hashes)
      noun = document_hashes.size > 1 ? "documents" : "document"
      logger.info "Indexing #{document_hashes.size} queued #{noun} into #{index_name}"

      begin
        index(index_name).bulk_index(document_hashes)
      rescue Elasticsearch::IndexLocked
        logger.info "Index #{index_name} is locked; rescheduling"
        self.class.perform_in(LOCK_DELAY, index_name, document_hashes)
      end
    end
  end
end
