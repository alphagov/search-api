require "uri"
require "elasticsearch/index_group"

module Elasticsearch
  class NoSuchIndex < ArgumentError; end

  class SearchServer
    DEFAULT_MAPPING_KEY = "default"

    def initialize(base_uri, schema, index_names)
      @base_uri = URI.parse(base_uri)
      @schema = schema
      @index_names = index_names
    end

    def index_group(prefix)
      IndexGroup.new(@base_uri, prefix, index_settings(prefix), mappings(prefix))
    end

    def index(prefix)
      if @index_names.include?(prefix)
        index_group(prefix).current
      else
        raise NoSuchIndex, prefix
      end
    end

    def all_indices
      @index_names.map do |index_name|
        index(index_name)
      end
    end

  private
    def index_settings(prefix)
      @schema["index"]
    end

    def mappings(prefix)
      mappings = @schema["mappings"]
      mappings[prefix] || mappings[DEFAULT_MAPPING_KEY]
    end
  end
end
