require "uri"
require "elasticsearch/index_group"
require "elasticsearch/index_for_search"

module Elasticsearch
  class NoSuchIndex < ArgumentError; end

  class SearchServer
    attr_reader :schema

    def initialize(base_uri, schema, index_names, content_index_names,
                   search_config)
      @base_uri = URI.parse(base_uri)
      @schema = schema
      @index_names = index_names
      @content_index_names = content_index_names
      @search_config = search_config
    end

    def index_group(prefix)
      IndexGroup.new(
        @base_uri,
        prefix,
        @schema,
        @search_config
      )
    end

    def index(prefix)
      raise NoSuchIndex, prefix unless index_name_valid?(prefix)
      index_group(prefix).current
    end

    def index_for_search(names)
      names.each do |name|
        raise NoSuchIndex, name unless index_name_valid?(name)
      end
      IndexForSearch.new(@base_uri, names, @schema, @search_config)
    end

    def content_indices
      @content_index_names.map do |index_name|
        index(index_name)
      end
    end

  private
    def index_name_valid?(index_name)
      index_name.split(",").all? do |name|
        @index_names.include?(name)
      end
    end
  end
end
