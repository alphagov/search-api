module GovukIndex
  class PageTrafficWorker < Indexer::BaseWorker
    BULK_INDEX_TIMEOUT = 60
    QUEUE_NAME = 'bulk'.freeze
    sidekiq_options queue: QUEUE_NAME

    def perform(records, destination_index)
      actions = Index::ElasticsearchProcessor.new(client: GovukIndex::Client.new(timeout: BULK_INDEX_TIMEOUT, index_name: destination_index))

      records.each_slice(2) do |identifier, document|
        actions.raw(identifier, document)
      end

      actions.commit
    end
  end
end
