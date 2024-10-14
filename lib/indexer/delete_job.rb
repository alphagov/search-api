module Indexer
  class DeleteJob < BaseJob
    notify_of_failures

    def perform(index_name, elasticsearch_type, document_id)
      logger.info "Deleting #{elasticsearch_type} document '#{document_id}' of type '#{elasticsearch_type}' from '#{index_name}'"

      begin
        indexes(index_name).each { |index| index.delete(document_id) }
      rescue SearchIndices::IndexLocked
        logger.info "Index #{index_name} is locked; rescheduling"
        self.class.perform_in(LOCK_DELAY, index_name, elasticsearch_type, document_id)
      end
    end
  end
end
