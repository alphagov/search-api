module GovukIndex
  class ElasticsearchPresenter
    def initialize(payload, type)
      @payload = payload
      @type = type
    end

    def identifier
      {
        _type: type,
        _id: id,
        version: payload["payload_version"],
        version_type: "external",
      }
    end

    def document
      {
        link: payload["base_path"],
        title: payload["title"],
        is_withdrawn: withdrawn?,
        content_store_document_type: payload["document_type"],
      }
    end

    def id
      payload["base_path"]
    end

    def valid!
      return if payload["base_path"]
      raise(ValidationError, "base_path missing from payload")
    end

  private

    attr_reader :payload, :type

    def withdrawn?
      !payload["withdrawn_notice"].nil?
    end
  end
end
