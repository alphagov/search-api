require "json"
require "yaml"
require "schema/index_schema"

class SchemaConfig
  def initialize(config_path)
    @config_path = config_path
    @index_schemas = IndexSchemaParser.parse_all(config_path)
  end

  def schema_for_alias_name(alias_name)
    @index_schemas.each do |index_name, schema|
      if alias_name.start_with?(index_name)
        return schema
      end
    end
    raise RuntimeError("No schema found for alias `#{alias_name}")
  end

  def elasticsearch_settings(index_name)
    @settings ||= elasticsearch_index["settings"]
  end

  def elasticsearch_mappings(index_name)
    index_name = index_name.sub(/[-_]test$/, '')
    special_mappings = schema_yaml["mappings"]
    if special_mappings.include?(index_name)
      special_mappings[index_name]
    else
      @index_schemas.fetch(index_name).es_mappings
    end
  end

private
  attr_reader :config_path

  def schema_yaml
    load_yaml("elasticsearch_schema.yml")
  end

  def elasticsearch_index
    schema_yaml["index"].tap do |index|
      index["settings"]["analysis"]["filter"].merge!(
        "synonym" => synonym_filter,
        "stemmer_override" => stems_filter,
      )
    end
  end

  def synonym_filter
    load_yaml("synonyms.yml")
  end

  def stems_filter
    load_yaml("stems.yml")
  end

  def load_yaml(file_path)
    YAML.load_file(File.join(config_path, file_path))
  end
end
