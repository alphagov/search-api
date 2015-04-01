require "schema/field_definitions"
require "schema/document_types"

module SampleConfig

  def schema_dir
    File.expand_path('../config/schema', File.dirname(__FILE__))
  end

  def sample_field_definitions(fields=nil)
    @sample_field_definitions ||= FieldDefinitionParser.new(schema_dir).parse
    if fields.nil?
      @sample_field_definitions
    else
      @sample_field_definitions.select { |field, _|
        fields.include?(field)
      }
    end
  end

  def sample_document_types
    @sample_document_types ||= DocumentTypesParser.new(schema_dir, sample_field_definitions).parse
  end

  def sample_schema
    @sample_schema ||= SchemaConfig.new(schema_dir)
  end
end
