
class SchemaConfig
  attr_reader :field_definitions

  def initialize(config_path, schema_config_file: 'elasticsearch_schema.yml')
    @config_path = config_path
    @schema_config_file = schema_config_file
    @field_definitions = FieldDefinitionParser.new(config_path).parse
    @elasticsearch_types = ElasticsearchTypesParser.new(config_path, @field_definitions).parse
    @index_schemas = IndexSchemaParser.parse_all(config_path, @field_definitions, @elasticsearch_types)
    @index_synonyms, @search_synonyms = SynonymParser.new.parse(synonym_config)
  end

  def schema_for_alias_name(alias_name)
    @index_schemas.each do |index_name, schema|
      if alias_name.start_with?(index_name)
        return schema
      end
    end
    raise RuntimeError("No schema found for alias `#{alias_name}")
  end

  def elasticsearch_settings(_index_name)
    @settings ||= elasticsearch_index["settings"]
  end

  def elasticsearch_types(index_name)
    index_name = index_name.sub(/[-_]test$/, '')
    @index_schemas.fetch(index_name).elasticsearch_types
  end

  def elasticsearch_mappings(index_name)
    index_name = index_name.sub(/[-_]test$/, '')
    @index_schemas.fetch(index_name).es_mappings
  end

private

  attr_reader :config_path, :schema_config_file

  def synonym_config
    YAML.load_file(File.join(config_path, "synonyms.yml"))
  end

  def schema_yaml
    load_yaml(schema_config_file)
  end

  def elasticsearch_index
    schema_yaml["index"].tap do |index|
      index["settings"]["analysis"]["filter"].merge!(
        "stemmer_override" => stems_filter,
        "index_synonym" => @index_synonyms.es_config,
        "search_synonym" => @search_synonyms.es_config,
      )
    end
  end

  def stems_filter
    load_yaml("stems.yml")
  end

  def load_yaml(file_path)
    YAML.load_file(File.join(config_path, file_path))
  end
end
