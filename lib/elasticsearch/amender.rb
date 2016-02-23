module Elasticsearch
  class Amender
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def amend(link, updates)
      document = index.get(link)

      unless document
        raise Elasticsearch::DocumentNotFound, "`Index#get` can't find #{link}"
      end

      if updates.include? "link"
        raise ArgumentError, "Cannot change document links"
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
