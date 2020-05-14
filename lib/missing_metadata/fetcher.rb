# Queries publishing api to fill in missing metadata for search results
module MissingMetadata
  class Fetcher
    class MissingDocumentError < StandardError
    end

    def initialize(publishing_api)
      @publishing_api = publishing_api
    end

    def add_metadata(result)
      index_name = result[:index]
      document_id = result[:_id]
      raise MissingDocumentError, "Missing index name or id in search results" if index_name.nil? || document_id.nil?

      content_id = result[:content_id] || lookup_content_id(document_id)

      update_metadata(content_id, index_name, document_id)
    end

    def lookup_content_id(document_id)
      base_path = document_id
      base_path = "/" + base_path unless base_path.start_with?("/")

      content_id = publishing_api.lookup_content_id(base_path: base_path)

      content_id || raise(MissingDocumentError, "Failed to look up base path")
    rescue GdsApi::TimedOutException
      puts "Publishing API timed out getting content_id... retrying"
      sleep(1)
      retry
    end

    def update_metadata(content_id, index_name, document_id)
      response = publishing_api.get_content(content_id)

      Indexer::AmendWorker.perform_async(
        index_name,
        document_id,
        content_store_document_type: response["document_type"],
        publishing_app: response["publishing_app"],
        rendering_app: response["rendering_app"],
        content_id: content_id,
      )
    rescue GdsApi::TimedOutException
      puts "Publishing API timed out getting content... retrying"
      sleep(1)
      retry
    end

  private

    attr_reader :publishing_api
  end
end
