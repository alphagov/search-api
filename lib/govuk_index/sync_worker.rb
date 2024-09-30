module GovukIndex
  class SyncWorker < Indexer::BaseWorker
    BULK_INDEX_TIMEOUT = 60
    QUEUE_NAME = "bulk".freeze
    sidekiq_options queue: QUEUE_NAME

    def perform(record_ids, source_index_name, destination_index_name)
      actions = Index::ElasticsearchProcessor.new(client: GovukIndex::Client.new(timeout: BULK_INDEX_TIMEOUT, index_name: destination_index_name))

      source_index = IndexFinder.by_name(source_index_name)
      record_ids.each do |record_id|
        document = source_index.get_document_by_id(record_id)

        unless document
          puts "Skipping #{record_id} as it is not in the index"
          next
        end

        identifier = document.slice("_id", "_version", "_type")
        actions.save(
          OpenStruct.new(
            identifier: identifier.merge("version_type" => "external_gte"),
            document: document.fetch("_source"),
          ),
        )
      end

      actions.commit
    end
  end
end
