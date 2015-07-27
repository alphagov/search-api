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

    result = EntityExpander.new(registries).new_result(result)
    result[:snippet] = Snippet.new(result).text
    result
  end

private

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
      index = result[:_metadata]["_index"]
      index_schema = schema.schema_for_alias_name(index)
      document_type = result.fetch(:_metadata, {}).fetch("_type", nil)
      index_schema.document_type(document_type)
    end
  end
end
