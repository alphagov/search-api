module Indexer
  class DeleteWorker < BaseWorker
    notify_of_failures

    def perform(index_name, elasticsearch_type, document_id = nil)
      # Handle previous method signature to cope with leftover queued jobs when
      # we deploy.
      if document_id.nil?
        elasticsearch_type, document_id = index(index_name).link_to_type_and_id(elasticsearch_type)
      end

      logger.info "Deleting #{elasticsearch_type} document '#{document_id}' from '#{index_name}'"
      begin
        index(index_name).delete(elasticsearch_type, document_id)
      rescue SearchIndices::IndexLocked
        logger.info "Index #{index_name} is locked; rescheduling"
        self.class.perform_in(LOCK_DELAY, index_name, elasticsearch_type, document_id)
      end
    end
  end
end
