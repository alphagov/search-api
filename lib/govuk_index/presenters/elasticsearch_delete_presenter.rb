module GovukIndex
  class ElasticsearchDeletePresenter
    include ElasticsearchIdentity

    def initialize(payload:)
      @payload = payload
    end

    def base_path
      payload["base_path"]
    end

    def link
      base_path
    end

    def valid!
      unless payload["base_path"] || payload["content_id"]
        raise(NotIdentifiable, "base_path and content_id missing from payload")
      end
    end

    def type
      raise NotFoundError if existing_document.nil?
      source = existing_document["_source"]
      fallback = existing_document["_type"]
      if source
        source["document_type"] || fallback
      else
        fallback
      end
    end

  private

    attr_reader :payload

    def existing_document
      @_existing_document ||=
        begin
          Client.get(type: "_all", id: id)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          nil
        end
    end
  end
end
