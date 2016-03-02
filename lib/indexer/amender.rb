module Indexer
  class Amender
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def amend(link, updates)
      if updates.include?("link")
        raise ArgumentError, "Cannot change document the `link` attribute of a document."
      end

      document = index.get(link)

      unless document
        raise SearchIndices::DocumentNotFound, "`Index#get` can't find #{link}"
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
