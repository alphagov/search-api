require "active_support/inflector"
require "entity_expander"
require "snippet"

class ResultSetPresenter

  def initialize(result_set, context = {}, schema = nil)
    @result_set = result_set
    @context = context
    @schema = schema
  end

  def present
    {
      "total" => @result_set.total,
      "results" => results,
      "spelling_suggestions" => []
    }
  end

private
  def results
    @result_set.results.map { |document| build_result(document) }
  end

  def build_result(document)
    result = expand_metadata(document.to_hash)
    result = EntityExpander.new(@context).new_result(result)
    result[:snippet] = Snippet.new(result).text
    result
  end

  def expand_metadata(document_attrs)
    if @schema.nil?
      return document_attrs
    end

    document_schema = schema_for_document(document_attrs)

    document_attrs = apply_multivalued(document_schema, document_attrs)

    params_to_expand = document_attrs.select { |k, _|
      document_schema.allowed_values.include?(k)
    }

    expanded_params = params_to_expand.reduce({}) { |params, (field_name, values)|
      params.merge(
        field_name => Array(values).map { |raw_value|
          document_schema.allowed_values[field_name].find { |allowed_value|
            allowed_value.fetch("value") == raw_value
          }
        }
      )
    }

    document_attrs.merge(expanded_params)
  end

  def apply_multivalued(document_schema, document_attrs)
    document_attrs.reduce({}) { |result, (field_name, values)|
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
    }
  end

  def schema_for_document(document)
    index = document[:_metadata]["_index"]
    index_schema = @schema.schema_for_alias_name(index)
    index_schema.document_type(document_type(document))
  end

  def document_type(document)
    document.fetch(:_metadata, {}).fetch("_type", nil)
  end
end
