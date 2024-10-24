module SpecialistFinderIndex
  class DocumentTypeMapper
    UNPUBLISHING_TYPES = %w[gone redirect substitute vanish].freeze

    def initialize(payload)
      @payload = payload
    end

    def type
      @payload["document_type"]
    end

    def unpublishing_type?
      UNPUBLISHING_TYPES.include?(@payload["document_type"])
    end
  end
end
