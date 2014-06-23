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
    YAML.load_file(File.join(
      config_path,
      "elasticsearch_schema.yml",
    ))
  end

  def elasticsearch_index
    schema_yaml["index"]
  end

  def elasticsearch_mappings
    schema_yaml["mappings"]
  end
end
