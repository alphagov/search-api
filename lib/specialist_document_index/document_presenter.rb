module SpecialistDocumentIndex
  class DocumentPresenter
    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def identifier
      {
        _type: "generic-document",
        _id: payload["base_path"],
        version: payload["payload_version"],
        version_type: "external",
      }
    end

    def document
      payload.dig("details", "metadata")
             .merge({
                      content_id: payload["content_id"],
                      description: payload["description"],
                      format: payload["document_type"],
                      link: payload["base_path"],
                      public_timestamp: payload["public_updated_at"],
                      title: payload["title"],
                    })
    end
  end
end