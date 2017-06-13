require "lib/indexer/workers/amend_worker"

# Queries publishing api to fill in missing metadata for search results
class MissingMetadataFetcher
  class MissingDocumentError < StandardError
  end

  def initialize(publishing_api)
    @publishing_api = publishing_api
  end

  def add_metadata(result)
    content_id = result["content_id"]
    index_name = result["index"]
    document_id = result["_id"]

    if content_id.nil?
      base_path = document_id
      base_path = "/" + base_path unless base_path.start_with?("/")

      content_id = publishing_api.lookup_content_id(base_path: base_path)

      if content_id.nil?
        raise MissingDocumentError.new("Failed to look up base path")
      end

    elsif index_name.nil? || document_id.nil?
      raise MissingDocumentError.new("Missing index name or id in search results")
    end

    response = publishing_api.get_content(content_id)
    document_type = response["document_type"]
    publishing_app = response["publishing_app"]
    rendering_app = response["rendering_app"]

    updates = {
      content_store_document_type: document_type,
      publishing_app: publishing_app,
      rendering_app: rendering_app,
      content_id: content_id,
    }

    Indexer::AmendWorker.perform_async(index_name, document_id, updates)
  end

private

  attr_reader :publishing_api
end
