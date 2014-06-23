require "yaml"

class SchemaConfig
  def initialize(config_path)
    @config_path = config_path
  end

  def elasticsearch_schema
    {
      "index" => elasticsearch_index,
      "mappings" => elasticsearch_mappings,
    }
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

  def elasticsearch_mappings
    schema_yaml["mappings"]
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
