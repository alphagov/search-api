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

      raw_document = index.get_document_by_id(document_id)
      return unless raw_document

      document_source = raw_document["_source"]
      # For backwards-compatibility, ensure that the source _id is the
      # same as the main Elasticsearch _id
      document_source["_id"] = raw_document["_id"]

      document = index.document_from_hash(document_source)

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
