module LegacyClient
  # Elasticsearch returns all fields as arrays by default. We convert those
  # arrays into a single value here, unless we've explicitly set the field to
  # be "multivalued" in the database schema.
  class MultivalueConverter
    def initialize(fields, field_definitions)
      @fields = fields
      @field_definitions = field_definitions
    end

    def converted_hash
      result = @fields

      @fields.each do |field_name, values|
        values = Array.wrap(values)
        next if @field_definitions.fetch(field_name).type.multivalued

        @fields[field_name] = values.first
      end

      result
    end
  end
end
