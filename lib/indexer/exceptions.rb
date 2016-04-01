module Indexer
  class BulkIndexFailure < RuntimeError
    attr_reader :failed_keys

    def initialize(failed_items)
      super "Failed inserts: #{failed_items.map { |id, error| "#{id} (#{error})" }.join(', ')}"
      @failed_keys = failed_items.map { |id, _| id }
    end
  end
end
