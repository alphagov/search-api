module SearchIndices
  class NoSuchIndex < ArgumentError; end

  class SearchServer
    attr_reader :schema

    def initialize(base_uri, schema, search_config, index_names)
      @base_uri = base_uri
      @schema = schema
      @search_config = search_config
      @index_names = index_names
    end

    def index_group(prefix)
      IndexGroup.new(
        @base_uri,
        prefix,
        @schema,
        @search_config,
      )
    end

    def index(index_name)
      validate_index_name!(index_name)
      index_group(index_name).current
    end

    def index_for_search(names)
      names.each do |index_name|
        validate_index_name!(index_name)
      end
      LegacyClient::IndexForSearch.new(@base_uri, names, @schema, @search_config)
    end

  private

    def validate_index_name!(index_name)
      return if index_name_valid?(index_name)

      raise NoSuchIndex,
            "Index name #{index_name} is not specified in the elasticsearch settings."
    end

    def index_name_valid?(index_name)
      index_name.split(",").all? do |name|
        @index_names.include?(name)
      end
    end
  end
end
