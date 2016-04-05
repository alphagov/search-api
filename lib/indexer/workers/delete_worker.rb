require_relative "base_worker"

module Indexer
  class DeleteWorker < BaseWorker
    notify_of_failures

    def perform(index_name, document_type, document_id = nil)
      # Handle previous method signature to cope with leftover queued jobs when
      # we deploy.
      if document_id.nil?
        document_type, document_id = index(index_name).link_to_type_and_id(document_type)
      end

      logger.info "Deleting #{document_type} document '#{document_id}' from '#{index_name}'"
      begin
        index(index_name).delete(document_type, document_id)
      rescue SearchIndices::IndexLocked
        logger.info "Index #{index_name} is locked; rescheduling"
        self.class.perform_in(LOCK_DELAY, index_name, document_type, document_id)
      end
    end
  end
end
