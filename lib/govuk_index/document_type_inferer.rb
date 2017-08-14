module GovukIndex
  class DocumentTypeInferer
    UNPUBLISHING_TYPES = %w(gone redirect substitute vanish).freeze

    def initialize(payload)
      @payload = payload
    end

    def type
      if unpublishing_type?
        raise NotFoundError if existing_document.nil?
        existing_document['_type']
      else
        payload['document_type']
      end
    end

    def unpublishing_type?
      UNPUBLISHING_TYPES.include?(payload['document_type'])
    end

  private

    attr_reader :payload

    def existing_document
      @_existing_document ||= Client.get(type: '_all', id: payload['base_path'])
    end
  end
end
