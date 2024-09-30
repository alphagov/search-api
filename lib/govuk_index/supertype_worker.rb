module GovukIndex
  class SupertypeWorker < Indexer::BaseWorker
    BULK_INDEX_TIMEOUT = 60
    QUEUE_NAME = "bulk".freeze
    sidekiq_options queue: QUEUE_NAME

    def perform(record_ids, source_index_name, destination_index_name)
      actions = Index::ElasticsearchProcessor.new(client: GovukIndex::Client.new(timeout: BULK_INDEX_TIMEOUT, index_name: destination_index_name))

      source_index = IndexFinder.by_name(source_index_name)
      records = record_ids.filter_map do |id|
        document = source_index.get_document_by_id(record_id)

        unless document
          puts "Skipping #{record_id} as it is not in the index"
          next
        end

        {
          "identifier" => document.slice("_id", "_type", "_version"),
          "document" => document.fetch("_source"),
        }
      end

      updated_records = records.reject do |record|
        record["document"] == update_document_supertypes(record["document"])
      end

      updated_records.each do |record|
        actions.save(
          process_record(record),
        )
      end

      actions.commit
    end

    def process_record(record)
      OpenStruct.new(
        identifier: record["identifier"].merge("version_type" => "external_gte"),
        document: update_document_supertypes(record["document"]),
      )
    end

    def update_document_supertypes(doc_hash)
      doc_hash.merge(
        GovukDocumentTypes.supertypes(document_type: doc_hash["content_store_document_type"]),
      )
    end
  end
end
