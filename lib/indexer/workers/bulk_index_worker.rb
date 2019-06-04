module Indexer
  class BulkIndexWorker < BaseWorker
    notify_of_failures

    def perform(index_name, document_hashes)
      noun = document_hashes.size > 1 ? "documents" : "document"
      logger.info "Indexing #{document_hashes.size} queued #{noun} into #{index_name}"

      begin
        indexes(index_name).each { |index| index.bulk_index(document_hashes) }
      rescue SearchIndices::IndexLocked
        logger.info "Index #{index_name} is locked; rescheduling"
        self.class.perform_in(LOCK_DELAY, index_name, document_hashes)
      end
    end
  end
end
