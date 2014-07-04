require "elasticsearch/base_worker"

module Elasticsearch
  class DeleteWorker < BaseWorker
    forward_to_failure_queue

    def perform(index_name, document_type, document_id)
      logger.info "Deleting #{document_type} document '#{document_id}' from '#{index_name}'"
      begin
        index(index_name).delete(document_type, document_id)
      rescue Elasticsearch::IndexLocked
        logger.info "Index #{index_name} is locked; rescheduling"
        self.class.perform_in(LOCK_DELAY, index_name, document_type, document_id)
      end
    end
  end
end
