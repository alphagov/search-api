module Search
  class ResultPresenter
    attr_reader :raw_result, :registries, :schema, :search_params

    def initialize(raw_result, registries, schema, search_params, result_rank:)
      @raw_result = raw_result
      @registries = registries
      @schema = schema
      @search_params = search_params
      @result_rank = result_rank
    end

    def present
      source = EsExtract::Hits.source(raw_result) || {}

      if schema
        source = convert_elasticsearch_array_fields(source)
      end

      source = add_virtual_fields(source)
      source = expand_entities(source)
      source = temporarily_fix_link_field(source)
      source = only_return_explicitly_requested_values(source)
      source = present_parts(source)
      add_debug_values(source)
    end

  private

    DEFAULT_PARTS_TO_DISPLAY = 10
    TOP_N_RESULTS_TO_HAVE_PARTS = 3

    attr_reader :result_rank

    def expand_entities(source)
      EntityExpander.new(registries).new_result(source)
    end

    # The only fields which should be returned as arrays are ones
    # explicitly set to "multivalued" in the schema.  So if any other
    # fields have been returned as an array, pick the first value.
    def convert_elasticsearch_array_fields(source)
      source.each_with_object({}) do |(field_name, values), out|
        # drop fields not in the schema
        next unless document_schema.fields.key? field_name

        out[field_name] = values

        next if field_name[0] == "_"

        next if document_schema.fields.fetch(field_name).type.multivalued

        next unless values.is_a? Array

        out[field_name] = values.first
      end
    end

    def document_schema
      @document_schema ||= begin
        index_schema = schema.schema_for_alias_name(EsExtract::Hits.index(raw_result))
        index_schema.elasticsearch_type(EsExtract::Hits.source(raw_result)["document_type"])
      end
    end

    def add_debug_values(source)
      source[:index] = SearchIndices::Index.strip_alias_from_index_name(EsExtract::Hits.index(raw_result))

      # Put the elasticsearch score in es_score; this is used in templates when
      # debugging is requested, so it's nicer to be explicit about what score
      # it is.
      source[:es_score] = EsExtract::Hits.score(raw_result)

      source[:_id] = EsExtract::Hits.id(raw_result)

      if raw_result["_explanation"] && search_params.debug[:explain]
        source[:_explanation] = EsExtract::Hits.explanation(raw_result)
      end

      source[:elasticsearch_type] = EsExtract::Hits.source(raw_result)["document_type"]

      # TODO: clients should not use this. It's probably only used in the
      # search results in the `frontend` application.
      source[:document_type] = EsExtract::Hits.source(raw_result)["document_type"]

      source
    end

    def present_parts(source)
      parts = source["parts"]
      return source unless parts && parts.any?

      parts_count = result_rank <= TOP_N_RESULTS_TO_HAVE_PARTS ? DEFAULT_PARTS_TO_DISPLAY : 0
      source["parts"] = parts.take(parts_count)
      source
    end

    def add_virtual_fields(source)
      if search_params.field_requested?("title_with_highlighting")
        source["title_with_highlighting"] = HighlightedTitle.new(raw_result).text
      end

      if search_params.field_requested?("description_with_highlighting")
        source["description_with_highlighting"] = HighlightedDescription.new(raw_result).text
      end

      source
    end

    def only_return_explicitly_requested_values(result)
      result.slice(*search_params.return_fields)
    end

    def temporarily_fix_link_field(source)
      return source if source["link"].nil? ||
                       source["link"].starts_with?("http") ||
                       source["link"].starts_with?("/")

      source["link"] = "/#{source['link']}"
      source
    end
  end
end
