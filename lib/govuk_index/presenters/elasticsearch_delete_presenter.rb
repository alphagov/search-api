module GovukIndex
  class ElasticsearchDeletePresenter
    def initialize(payload:)
      @payload = payload
    end

    def identifier
      {
        _type: type,
        _id: base_path,
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

    def link
      base_path
    end

    def valid!
      link || raise(MissingBasePath, "base_path missing from payload")
    end

  private

    attr_reader :payload

    def existing_document
      @_existing_document ||=
        begin
          Client.get(type: '_all', id: payload['base_path'])
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          nil
        end
    end
  end
end
