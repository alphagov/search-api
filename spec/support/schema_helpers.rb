module SchemaHelpers
  SCHEMA_DIR = File.expand_path("../../config/schema", File.dirname(__FILE__))

  def sample_field_definitions(fields = nil)
    @sample_field_definitions ||= FieldDefinitionParser.new(SCHEMA_DIR).parse

    if fields.nil?
      @sample_field_definitions
    else
      @sample_field_definitions.select do |field, _|
        fields.include?(field)
      end
    end
  end

  def sample_elasticsearch_types
    @sample_elasticsearch_types ||= ElasticsearchTypesParser.new(SCHEMA_DIR, sample_field_definitions).parse
  end

  def sample_schema
    @sample_schema ||= SchemaConfig.new(SCHEMA_DIR)
  end
end
