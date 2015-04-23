class CombinedIndexSchema
  def initialize(index_names, schema)
    @index_names = index_names
    @schema = schema
  end

  def document_type(document_type_name)
    document_types[document_type_name]
  end

  def document_types
    @document_types ||= @index_names.inject({}) { |results, index_name|
      results.merge(@schema.document_types(index_name))
    }
  end

  # Get a hash from field_name to FieldDefinition object, for all fields
  # allowed in any document type in the indexes.
  #
  # Since FieldDefinitions can contain an "allowed_values" member, and this
  # may differ between document types, the definitions returned here will
  # have combined "allowed_values" fields, containing all the allowed values
  # for the field across all document types.
  def field_definitions
    @field_definitions ||= each_field_with_object({}) { |field_name, field_definition, results|
      results[field_name] = field_definition.merge(results[field_name])
    }
  end

private

  # Call &block for every field defined in any of the document types.
  # May make repeated calls for a given field.
  # Passes (field_name, field_definition, obj) to the block each time it is
  # called.
  # Returns obj.
  def each_field_with_object(obj, &block)
    document_types.values.each do |document_type|
      document_type.fields.each do |field_name, field_definition|
        yield field_name, field_definition, obj
      end
    end
    obj
  end
end
