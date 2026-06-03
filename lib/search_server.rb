module SearchIndices
  class NoSuchIndex < ArgumentError; end

  class SearchServer
    attr_reader :schema

    def initialize(base_uri, schema, search_config)
      @base_uri = base_uri
      @schema = schema
      @search_config = search_config
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

  private

    def validate_index_name!(index_name)
      return if index_name_valid?(index_name)

      raise NoSuchIndex,
            "Index name #{index_name} is not specified in the elasticsearch settings."
    end

    def index_name_valid?(index_name)
      index_name.split(",").all? do |name|
        SearchConfig.all_index_names.include?(name)
      end
    end
  end
end
