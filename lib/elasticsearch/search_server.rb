require "uri"

module Elasticsearch
  class SearchServer
    DEFAULT_MAPPING_KEY = "default"

    def initialize(base_uri, schema)
      @base_uri = URI.parse(base_uri)
      @schema = schema
    end

    def index_group(prefix)
      IndexGroup.new(@base_uri, prefix, index_settings(prefix), mappings(prefix))
    end

    def index(prefix)
      index_group(prefix).current
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
