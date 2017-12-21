module GovukIndex
  class DocumentTypeInferrer
    UNPUBLISHING_TYPES = %w(gone redirect substitute vanish).freeze

    def initialize(payload)
      @payload = payload
    end

    def type
      if unpublishing_type?
        raise NotFoundError if existing_document.nil?
        existing_document['_type']
      else
        elasticsearch_document_type
      end
    end

    def unpublishing_type?
      UNPUBLISHING_TYPES.include?(payload['document_type'])
    end

  private

    attr_reader :payload

    def mapped_document_types
      @_document_types ||= begin
        YAML.load_file(File.join(__dir__, '../../config/govuk_index/mapped_document_types.yaml'))
      end
    end

    def existing_document
      @_existing_document ||=
        begin
          Client.get(type: '_all', id: payload['base_path'])
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          nil
        end
    end

    def elasticsearch_document_type
      @_elasticsearch_document_type ||= mapped_document_types[payload['document_type']]
    end
  end
end
