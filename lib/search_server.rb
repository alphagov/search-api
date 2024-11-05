module SearchIndices
  class NoSuchIndex < ArgumentError; end

  class SearchServer
    attr_reader :schema

    def initialize(base_uri, schema, index_names, govuk_index_name, content_index_names,
                   search_config)
      @base_uri = base_uri
      @schema = schema
      @index_names = index_names
      @govuk_index_name = govuk_index_name
      @content_index_names = content_index_names
      @search_config = search_config
      @specialist_finder_index_name = SearchConfig.specialist_finder_index_name
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

    def content_indices
      @content_index_names.map do |index_name|
        index(index_name)
      end
    end

  private

    def validate_index_name!(index_name)
      return if index_name_valid?(index_name)

      raise NoSuchIndex,
            "Index name #{index_name} is not specified in the elasticsearch settings."
    end

    def index_name_valid?(index_name)
      index_name.split(",").all? do |name|
        @index_names.include?(name) || @govuk_index_name == name || @specialist_finder_index_name == name
      end
    end
  end
end
