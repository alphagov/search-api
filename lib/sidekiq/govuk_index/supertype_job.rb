module GovukIndex
  class SupertypeJob < BaseJob
    BULK_INDEX_TIMEOUT = 60
    QUEUE_NAME = "bulk".freeze
    sidekiq_options queue: QUEUE_NAME

    def perform(document_ids, index_name)
      actions = Index::ElasticsearchProcessor.new(client: GovukIndex::Client.new(timeout: BULK_INDEX_TIMEOUT, index_name:))

      index = IndexFinder.by_name(index_name)
      documents = document_ids.filter_map do |document_id|
        document = index.get_document_by_id(document_id)

        unless document
          logger.warn "Skipping #{document_id} as it is not in the index"
          next
        end
        {
          "identifier" => document.slice("_id", "_type", "_version"),
          "document" => document.fetch("_source"),
        }
      end

      updated_documents = documents.reject do |document|
        document["document"] == update_document_supertypes(document["document"])
      end

      updated_documents.each do |document|
        actions.save(
          process_document(document),
        )
      end

      actions.commit
    end

    def process_document(document)
      OpenStruct.new(
        identifier: document["identifier"].merge("version_type" => "external_gte"),
        document: update_document_supertypes(document["document"]),
      )
    end

    def update_document_supertypes(doc_hash)
      doc_hash.merge(
        GovukDocumentTypes.supertypes(document_type: doc_hash["content_store_document_type"]),
      )
    end
  end
end
