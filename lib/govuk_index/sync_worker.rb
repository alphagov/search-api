module GovukIndex
  class SyncWorker < Indexer::BaseWorker
    BULK_INDEX_TIMEOUT = 60
    QUEUE_NAME = "bulk".freeze
    sidekiq_options queue: QUEUE_NAME

    def perform(records, destination_index)
      actions = Index::ElasticsearchProcessor.new(client: GovukIndex::Client.new(timeout: BULK_INDEX_TIMEOUT, index_name: destination_index))

      records.each do |record|
        actions.save(
          OpenStruct.new(
            identifier: record["identifier"].merge("_version_type" => "external_gte"),
            document: record["document"],
          ),
        )
      end

      actions.commit
    end
  end
end
