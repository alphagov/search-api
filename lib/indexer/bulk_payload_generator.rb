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
    #   {"index": {"_type": "edition", "_id": "/bank-holidays"}}
    #   { <document source> }
    #   {"index": {"_type": "edition", "_id": "/something-else"}}
    #   { <document source> }
    #
    # See <http://www.elasticsearch.org/guide/reference/api/bulk/>
    def bulk_payload(document_hashes_or_payload, options)
      if document_hashes_or_payload.is_a?(Array)
        index_items = index_items_from_document_hashes(document_hashes_or_payload, options)
      else
        index_items = index_items_from_raw_string(document_hashes_or_payload, options)
      end

      # Make sure the payload ends with a newline character: elasticsearch
      # requires this.
      index_items.flatten.join("\n") + "\n"
    end

  private

    def index_items_from_document_hashes(document_hashes, options)
      links = document_hashes.map {
        |doc_hash| doc_hash["link"]
      }.compact
      popularities = lookup_popularities(links)
      document_hashes.map { |doc_hash|
        [index_action(doc_hash).to_json, index_doc(doc_hash, popularities, options).to_json]
      }
    end

    def lookup_popularities(links)
      Indexer::PopularityLookup.new(@index_name, @search_config).lookup_popularities(links)
    end

    def index_action(doc_hash)
      {
        "index" => {
          "_type" => doc_hash["_type"],
          "_id" => (doc_hash["_id"] || doc_hash["link"])
        }
      }
    end

    def index_doc(doc_hash, popularities, options)
      Indexer::DocumentPreparer.new(@client).prepared(
        doc_hash,
        popularities,
        options,
        @is_content_index
      )
    end

    def index_items_from_raw_string(payload, options)
      actions = []
      links = []
      payload.each_line.each_slice(2).map do |command, doc|
        command_hash = JSON.parse(command)
        doc_hash = JSON.parse(doc)
        actions << [command_hash, doc_hash]
        links << doc_hash["link"]
      end
      popularities = lookup_popularities(links.compact)
      actions.map { |command_hash, doc_hash|
        if command_hash.keys == ["index"]
          doc_hash["_type"] = command_hash["index"]["_type"]
          [
            command_hash.to_json,
            index_doc(doc_hash, popularities, options).to_json
          ]
        else
          [
            command_hash.to_json,
            doc_hash.to_json
          ]
        end
      }
    end
  end
end
