class CombinedIndexSchema
  def initialize(index_names, schema)
    @index_names = index_names
    @schema = schema
  end

  def opensearch_type(opensearch_type_name)
    opensearch_types[opensearch_type_name]
  end

  def opensearch_types
    @opensearch_types ||= @index_names.inject({}) do |results, index_name|
      results.merge(@schema.opensearch_types(index_name))
    end
  end

  # Get a hash from field_name to FieldDefinition object, for all fields
  # allowed in any document type in the indexes.
  def field_definitions
    @field_definitions ||= each_field_with_object({}) do |field_name, field_definition, results|
      results[field_name] = field_definition
    end
  end

  # Get the names of fields which are allowed to be filtered on.
  #
  # This is all fields which have a FieldType for which "filter_type" is defined.
  def allowed_filter_fields
    @allowed_filter_fields ||= each_field_with_object(Set.new) { |field_name, field_definition, results|
      if field_definition.type.filter_type
        results << field_name
      end
    }.to_a
  end

private

  # Call &block for every field defined in any of the document types.
  # May make repeated calls for a given field.
  # Passes (field_name, field_definition, obj) to the block each time it is
  # called.
  # Returns obj.
  def each_field_with_object(obj, &_block)
    opensearch_types.each_value do |opensearch_type|
      opensearch_type.fields.each do |field_name, field_definition|
        yield field_name, field_definition, obj
      end
    end
    obj
  end
end
