require "json"
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
    schema_yaml["mappings"].merge(
      "default" => doctype_schemas,
    )
  end

  def core_doctype_schema
    load_json("default/core.json")
  end

  def doctype_schemas
    files = Dir.new(doctype_path).select { |filename|
      filename =~ /\A[a-z]+(_[a-z]+)*\.json\z/
    }

    files.each.with_object({}) do |filename, doctypes|
      doctype = filename.split(".").first
      doctypes[doctype] = load_doctype(filename)
    end
  end

  def load_doctype(filename)
    doctype_schema = load_json("default/doctypes/#{filename}")

    # Strip the details key from each property -- it contains stuff that
    # shouldn't be sent to elasticsearch
    doctype_schema["properties"].each do |property, settings|
      settings.reject! { |key, _| key == "details" }
    end

    deep_merge(
      core_doctype_schema,
      load_json("default/doctypes/#{filename}"),
    )
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

  def load_json(file_path)
    JSON.parse(File.read(File.join(config_path, file_path), encoding: 'UTF-8'))
  end

  def doctype_path
    File.join(config_path, "default", "doctypes")
  end

  def deep_merge(base_hash, other_hash)
    base_hash.merge(other_hash) { |_, base_value, other_value|
      deep_merge(base_value, other_value)
    }
  end
end
