require "elasticsearch/bulk_index_worker"
require "elasticsearch/delete_worker"

module Elasticsearch
  # A queue of operations on an index.
  class IndexQueue

    def initialize(index_name)
      @index_name = index_name
    end

    def queue_many(document_hashes)
      BulkIndexWorker.perform_async(@index_name, document_hashes)
    end

    def queue_delete(link)
      DeleteWorker.perform_async(@index_name, link)
    end
  end
end
