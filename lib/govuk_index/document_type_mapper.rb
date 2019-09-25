module GovukIndex
  class DocumentTypeMapper
    UNPUBLISHING_TYPES = %w(gone redirect substitute vanish).freeze

    def initialize(payload)
      @payload = payload
    end

    def type
      elasticsearch_document_type
    end

    def unpublishing_type?
      UNPUBLISHING_TYPES.include?(payload["document_type"])
    end

  private

    attr_reader :payload

    def mapped_document_types
      @mapped_document_types ||= begin
        YAML.load_file(File.join(__dir__, "../../config/govuk_index/mapped_document_types.yaml"))
      end
    end

    def elasticsearch_document_type
      @elasticsearch_document_type ||= mapped_document_types[payload["document_type"]]
    end
  end
end
