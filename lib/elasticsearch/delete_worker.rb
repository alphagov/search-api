require "elasticsearch/base_worker"

module Elasticsearch
  class DeleteWorker < BaseWorker
    forward_to_failure_queue

    def perform(index_name, document_link)
      logger.info "Deleting document '#{document_link}' from '#{index_name}'"
      index(index_name).delete(document_link)
    end
  end
end
