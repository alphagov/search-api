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

    document_attrs = apply_multivalued

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

  def apply_multivalued
    document_attrs = document.to_hash
    document_attrs.reduce({}) do |result, (field_name, values)|
      if field_name[0] == '_'
        # Special fields are always returned as single values.
        result[field_name] = values
        return result
      end

      # Convert to array for consistency between elasticsearch 0.90 and 1.0.
      # When we no longer support elasticsearch <1.0, values here will
      # always be an array, so this block can be removed.
      if values.nil?
        values = []
      elsif !(values.is_a?(Array))
        values = [values]
      end

      if document_schema.fields.fetch(field_name).type.multivalued
        result[field_name] = values
      else
        result[field_name] = values.first
      end
      result
    end
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
