module GovukIndex
  class ElasticsearchDeletePresenter
    def initialize(payload:)
      @payload = payload
    end

    def identifier
      {
        _type: type,
        _id: id,
        version: payload["payload_version"],
        version_type: "external",
      }
    end

    def type
      raise NotFoundError if existing_document.nil?
      existing_document['_type']
    end

    def base_path
      payload["base_path"]
    end

    def id
      base_path || payload["content_id"]
    end

    def link
      base_path
    end

    def valid!
      unless payload["base_path"] || payload["content_id"]
        raise(NotIdentifiable, "base_path and content_id missing from payload")
      end
    end

  private

    attr_reader :payload

    def existing_document
      @_existing_document ||=
        begin
          Client.get(type: '_all', id: id)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          nil
        end
    end
  end
end
