require "entity_expander"
require "snippet"

class ResultPresenter
  attr_reader :raw_result, :registries, :schema

  def initialize(raw_result, registries, schema)
    @raw_result = raw_result
    @registries = registries
    @schema = schema
  end

  def present
    result = raw_result['fields'] || {}

    if schema
      result = convert_elasticsearch_array_fields(result)
      result = expand_allowed_values(result)
    end

    result = expand_entities(result)
    result = add_calculated_fields(result)
    result = add_debug_values(result)
    result
  end

private

  def expand_entities(result)
    EntityExpander.new(registries).new_result(result)
  end

  def expand_allowed_values(result)
    params_to_expand = result.select do |k, _|
      document_schema.allowed_values.include?(k)
    end

    expanded_params = params_to_expand.reduce({}) do |params, (field_name, values)|
      params.merge(
        field_name => Array(values).map { |raw_value|
          document_schema.allowed_values[field_name].find { |allowed_value|
            allowed_value.fetch("value") == raw_value
          }
        }
      )
    end

    result.merge(expanded_params)
  end

  # Elasticsearch returns all fields as arrays by default. We convert those
  # arrays into a single value here, unless we've explicitly set the field to
  # be "multivalued" in the database schema.
  def convert_elasticsearch_array_fields(result)
    result.each do |field_name, values|
      next if field_name[0] == '_'
      next if document_schema.fields.fetch(field_name).type.multivalued
      result[field_name] = values.first
    end
    result
  end

  def document_schema
    @document_schema ||= begin
      index_schema = schema.schema_for_alias_name(raw_result["_index"])
      index_schema.document_type(raw_result["_type"])
    end
  end

  def add_debug_values(result)
    # Advanced search only passes through data, not the entire raw result.
    return result unless raw_result["_index"]

    # Translate index names like `mainstream-2015-05-06t09..` into its
    # proper name, eg. "mainstream", "government" or "service-manual".
    # The regex takes the string until the first digit. After that, strip any
    # trailing dash from the string.
    result[:index] = raw_result["_index"].match(%r[^\D+]).to_s.chomp('-')

    # Put the elasticsearch score in es_score; this is used in templates when
    # debugging is requested, so it's nicer to be explicit about what score
    # it is.
    result[:es_score] = raw_result["_score"]
    result[:_id] = raw_result["_id"]

    if raw_result["_explanation"]
      result[:_explanation] = raw_result["_explanation"]
    end

    result[:document_type] = raw_result["_type"]
    result
  end

  def add_calculated_fields(result)
    result[:snippet] = Snippet.new(result).text
    result
  end
end
