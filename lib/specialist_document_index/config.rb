module SpecialistDocumentIndex
  class Config
    def self.specialist_document_types
      @specialist_document_types ||= YAML.load_file(File.join(__dir__, "../../config/specialist_document_index/specialist_document_types.yaml"))
    end

    def self.unpublishing_document_types
      %w[gone redirect substitute vanish].freeze
    end
  end
end