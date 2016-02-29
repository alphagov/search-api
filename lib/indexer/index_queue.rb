require "indexer/workers/bulk_index_worker"
require "indexer/workers/delete_worker"
require "indexer/workers/amend_worker"

module Indexer
  # A queue of operations on an index.
  class IndexQueue
    def initialize(index_name)
      @index_name = index_name
    end

    def queue_many(document_hashes)
      BulkIndexWorker.perform_async(@index_name, document_hashes)
    end

    def queue_delete(document_type, document_id)
      DeleteWorker.perform_async(@index_name, document_type, document_id)
    end

    def queue_amend(link, updates)
      AmendWorker.perform_async(@index_name, link, updates)
    end
  end
end
