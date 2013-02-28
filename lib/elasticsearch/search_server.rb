require "uri"

module Elasticsearch
  class SearchServer
    DEFAULT_MAPPING_KEY = "default"

    attr_reader :base_url

    def initialize(base_url, schema)
      @base_url = URI.parse(base_url)
      @schema = schema
    end

    def index_group(prefix)
      IndexGroup.new(self, prefix, index_settings(prefix), mappings(prefix))
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
