module Search
  class ResultPresenter
    attr_reader :raw_result, :registries, :schema, :search_params

    def initialize(raw_result, registries, schema, search_params)
      @raw_result = raw_result
      @registries = registries
      @schema = schema
      @search_params = search_params
    end

    def present
      result = raw_result['_source'] || {}

      if schema
        result = convert_elasticsearch_array_fields(result)
        result = expand_fields_from_schema(result)
      end

      result = add_virtual_fields(result)
      result = expand_entities(result)
      result = temporarily_fix_link_field(result)
      result = only_return_explicitly_requested_values(result)
      result = add_debug_values(result)

      result
    end

  private

    def expand_entities(result)
      EntityExpander.new(registries).new_result(result)
    end

    def expand_fields_from_schema(result)
      params_to_expand = result.select do |k, _|
        document_schema.expanded_search_result_fields.include?(k)
      end

      expanded_params = params_to_expand.reduce({}) do |params, (field_name, values)|
        params.merge(
          field_name => Array(values).map { |raw_value|
            document_schema.expanded_search_result_fields[field_name].find { |allowed_value|
              allowed_value.fetch("value") == raw_value
            }
          }
        )
      end

      result.merge(expanded_params)
    end

    # The only fields which should be returned as arrays are ones
    # explicitly set to "multivalued" in the schema.  So if any other
    # fields have been returned as an array, pick the first value.
    def convert_elasticsearch_array_fields(result)
      result.each_with_object({}) do |(field_name, values), out|
        # drop fields not in the schema
        next unless document_schema.fields.has_key? field_name
        out[field_name] = values
        next if field_name[0] == '_'
        next if document_schema.fields.fetch(field_name).type.multivalued
        next unless values.is_a? Array
        out[field_name] = values.first
      end
    end

    def document_schema
      @document_schema ||= begin
        index_schema = schema.schema_for_alias_name(raw_result["_index"])
        index_schema.elasticsearch_type(raw_result["_type"])
      end
    end

    def add_debug_values(result)
      # Advanced search only passes through data, not the entire raw result.
      return result unless raw_result["_index"]

      result[:index] = SearchIndices::Index.strip_alias_from_index_name(raw_result["_index"])

      # Put the elasticsearch score in es_score; this is used in templates when
      # debugging is requested, so it's nicer to be explicit about what score
      # it is.
      result[:es_score] = raw_result["_score"]
      result[:_id] = raw_result["_id"]

      if raw_result["_explanation"]
        result[:_explanation] = raw_result["_explanation"]
      end

      result[:elasticsearch_type] = raw_result["_type"]

      # TODO: clients should not use this. It's probably only used in the
      # search results in the `frontend` application.
      result[:document_type] = raw_result["_type"]

      result
    end

    def add_virtual_fields(result)
      if search_params.field_requested?('title_with_highlighting')
        result['title_with_highlighting'] = HighlightedTitle.new(raw_result).text
      end

      if search_params.field_requested?('description_with_highlighting')
        result['description_with_highlighting'] = HighlightedDescription.new(raw_result).text
      end

      result
    end

    def only_return_explicitly_requested_values(result)
      result.slice(*search_params.return_fields)
    end

    def temporarily_fix_link_field(result)
      return result if result['link'].nil? ||
          result['link'].starts_with?('http') ||
          result['link'].starts_with?('/')

      result['link'] = '/' + result['link']
      result
    end
  end
end
