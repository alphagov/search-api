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
    result = expand_metadata
    result = EntityExpander.new(registries).new_result(result)
    result[:snippet] = Snippet.new(result).text
    result
  end

private

  def expand_metadata
    return document.to_hash if schema.nil?

    document_attrs = convert_elasticsearch_array_fields

    params_to_expand = document_attrs.select do |k, _|
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

    document_attrs.merge(expanded_params)
  end

  # Elasticsearch returns all fields as arrays by default. We convert those
  # arrays into a single value here, unless we've explicitly set the field to
  # be "multivalued" in the database schema.
  def convert_elasticsearch_array_fields
    document_attrs = document.to_hash
    document_attrs.each do |field_name, values|
      next if field_name[0] == '_'
      next if document_schema.fields.fetch(field_name).type.multivalued
      document_attrs[field_name] = values.first
    end
    document_attrs
  end

  def document_schema
    @document_schema ||= begin
      document_attrs = document.to_hash
      index = document_attrs[:_metadata]["_index"]
      index_schema = schema.schema_for_alias_name(index)
      document_type = document_attrs.fetch(:_metadata, {}).fetch("_type", nil)
      index_schema.document_type(document_type)
    end
  end
end
