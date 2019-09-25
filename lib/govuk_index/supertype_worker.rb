module GovukIndex
  class SupertypeWorker < Indexer::BaseWorker
    BULK_INDEX_TIMEOUT = 60
    QUEUE_NAME = "bulk".freeze
    sidekiq_options queue: QUEUE_NAME

    def perform(records, destination_index)
      actions = Index::ElasticsearchProcessor.new(client: GovukIndex::Client.new(timeout: BULK_INDEX_TIMEOUT, index_name: destination_index))

      updated_records = records.reject { |record|
        record["document"] == update_document_supertypes(record["document"])
      }

      updated_records.each do |record|
        actions.save(
          process_record(record)
        )
      end

      actions.commit
    end

    def process_record(record)
      OpenStruct.new(
        identifier: record["identifier"].merge("_version_type" => "external_gte"),
        document: update_document_supertypes(record["document"])
      )
    end

    def update_document_supertypes(doc_hash)
      doc_hash.merge(
        GovukDocumentTypes.supertypes(document_type: doc_hash["content_store_document_type"])
      )
    end
  end
end
