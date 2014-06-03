require "uri"
require "elasticsearch/index_group"

module Elasticsearch
  class NoSuchIndex < ArgumentError; end

  class SearchServer
    DEFAULT_MAPPING_KEY = "default"

    def initialize(base_uri, schema, index_names, content_index_names,
                   search_config)
      @base_uri = URI.parse(base_uri)
      @schema = schema
      @index_names = index_names
      @content_index_names = content_index_names
      @search_config = search_config
    end

    def index_group(prefix)
      IndexGroup.new(@base_uri, prefix, index_settings(prefix), mappings(prefix), @search_config)
    end

    def index(prefix)
      raise NoSuchIndex, prefix unless index_name_valid?(prefix)
      index_group(prefix).current
    end

    def content_indices
      @content_index_names.map do |index_name|
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

    def index_name_valid?(index_name)
      index_name.split(",").all? do |name|
        @index_names.include?(name)
      end
    end
  end
end
