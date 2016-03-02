module Indexer
  class Amender
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def amend(document_id, updates)
      if updates.include?("link")
        raise ArgumentError, "Cannot change document the `link` attribute of a document."
      end

      document = index.get_document_by_id(document_id)

      unless document
        raise SearchIndices::DocumentNotFound,
          "Can't find document with _id #{document_id}"
      end

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
