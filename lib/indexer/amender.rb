module Indexer
  class Amender
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def amend(document_id, updates)
      if updates.include?("link")
        raise ArgumentError, "Cannot change the `link` attribute of a document."
      end

      document = index.get_document_by_id(document_id)

      return unless document

      updates.each do |key, value|
        if document.has_field?(key)
          document.set key, value
        else
          raise ArgumentError, "Unrecognised field '#{key}'"
        end
      end

      index.add([document])
      true
    end
  end
end
