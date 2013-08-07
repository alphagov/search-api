require "elasticsearch/base_worker"

module Elasticsearch
  class DeleteWorker < BaseWorker
    forward_to_failure_queue

    LOCK_DELAY = 60  # seconds

    def perform(index_name, document_link)
      logger.info "Deleting document '#{document_link}' from '#{index_name}'"
      begin
        index(index_name).delete(document_link)
      rescue Elasticsearch::IndexLocked
        logger.info "Index #{index_name} is locked; rescheduling"
        self.class.perform_in(LOCK_DELAY, index_name, document_link)
      end
    end
  end
end
