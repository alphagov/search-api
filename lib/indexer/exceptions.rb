module Indexer
  class BulkIndexFailure < RuntimeError
    def initialize(failed_items)
      super "Failed inserts: #{failed_items.map { |id, error| "#{id} (#{error})" }.join(', ')}"
    end
  end
end
