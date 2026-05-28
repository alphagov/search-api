module SearchIndices
  class NoSuchIndex < ArgumentError; end

  class SearchServer
    attr_reader :schema

    def initialize(base_uri, schema, auxiliary_index_names, govuk_index_name,
                   search_config)
      @base_uri = base_uri
      @schema = schema
      @auxiliary_index_names = auxiliary_index_names
      @govuk_index_name = govuk_index_name
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
        @auxiliary_index_names.include?(name) || @govuk_index_name == name
      end
    end
  end
end
