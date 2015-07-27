require "entity_expander"
require "snippet"

class ResultPresenter
  attr_reader :document, :registries, :schema

  def initialize(document, registries, schema)
    @document = document
    @registries = registries
    @schema = schema
  end

  def present
    result = document.to_hash

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
      result = document.to_hash
      index = result[:_raw_result]["_index"]
      index_schema = schema.schema_for_alias_name(index)
      document_type = result.fetch(:_raw_result, {}).fetch("_type", nil)
      index_schema.document_type(document_type)
    end
  end

  def add_debug_values(result)
    return result unless result[:_raw_result]

    # Translate index names like `mainstream-2015-05-06t09..` into its
    # proper name, eg. "mainstream", "government" or "service-manual".
    # The regex takes the string until the first digit. After that, strip any
    # trailing dash from the string.
    result[:index] = result[:_raw_result]["_index"].match(%r[^\D+]).to_s.chomp('-')

    # Put the elasticsearch score in es_score; this is used in templates when
    # debugging is requested, so it's nicer to be explicit about what score
    # it is.
    result[:es_score] = result[:_raw_result]["_score"]
    result[:_id] = result[:_raw_result]["_id"]

    if result[:_raw_result]["_explanation"]
      result[:_explanation] = result[:_raw_result]["_explanation"]
    end

    result[:document_type] = result[:_raw_result]["_type"]
    result
  end

  def add_calculated_fields(result)
    result[:snippet] = Snippet.new(result).text
    result
  end
end
