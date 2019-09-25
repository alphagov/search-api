module Indexer
  class BulkPayloadGenerator
    def initialize(index_name, search_config, client, is_content_index)
      @index_name = index_name
      @search_config = search_config
      @client = client
      @is_content_index = is_content_index
    end

    # Payload to index documents using the `_bulk` endpoint
    #
    # The format is as follows:
    #
    #   {"index": {"_type": "generic-document", "_id": "/bank-holidays"}}
    #   { <document source> }
    #   {"index": {"_type": "generic-document", "_id": "/something-else"}}
    #   { <document source> }
    #
    # See <http://www.elasticsearch.org/guide/reference/api/bulk/>
    def bulk_payload(document_hashes_or_payload)
      if document_hashes_or_payload.is_a?(Array)
        index_items_from_document_hashes(document_hashes_or_payload)
      else
        index_items_from_raw_string(document_hashes_or_payload)
      end
    end

  private

    def index_items_from_document_hashes(document_hashes)
      links = document_hashes.map { |doc_hash|
        doc_hash["link"]
      }.compact
      popularities = lookup_popularities(links)
      document_hashes.flat_map { |doc_hash|
        [index_action(doc_hash), index_doc(doc_hash, popularities)]
      }
    end

    def lookup_popularities(links)
      Indexer::PopularityLookup.new(@index_name, @search_config).lookup_popularities(links)
    end

    def index_action(doc_hash)
      {
        "index" => {
          "_type" => "generic-document",
          "_id" => (doc_hash["_id"] || doc_hash["link"]),
        },
      }
    end

    def index_doc(doc_hash, popularities)
      DocumentPreparer.new(@client, @index_name).prepared(
        doc_hash,
        popularities,
        @is_content_index
      )
    end

    def index_items_from_raw_string(payload)
      actions = []
      links = []
      payload.each_line.each_slice(2).map do |command, doc|
        command_hash = JSON.parse(command)
        doc_hash = JSON.parse(doc)
        actions << [command_hash, doc_hash]
        links << doc_hash["link"]
      end
      popularities = lookup_popularities(links.compact)
      actions.flat_map { |command_hash, doc_hash|
        if command_hash.keys == ["index"]
          [
            command_hash,
            index_doc(doc_hash, popularities),
          ]
        else
          [
            command_hash,
            doc_hash,
          ]
        end
      }
    end
  end
end
