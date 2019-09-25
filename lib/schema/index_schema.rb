class IndexSchema
  attr_reader :name, :elasticsearch_types

  def initialize(name, field_definitions, elasticsearch_types)
    @name = name
    @elasticsearch_types = Hash[elasticsearch_types.map { |elasticsearch_type|
      [elasticsearch_type.name, elasticsearch_type]
    }]
    @document_type_field = field_definitions["document_type"][:es_config]
  end

  def es_mappings
    properties = {
      "document_type" => @document_type_field,
    }
    @elasticsearch_types.each do |_key, value|
      properties = properties.merge(value.es_config)
    end
    mappings = {
      "generic-document" => {
        "_all" => { "enabled" => false },
        "properties" => properties
      }
    }
    mappings
  end

  def elasticsearch_type(elasticsearch_type_name)
    @elasticsearch_types[elasticsearch_type_name]
  end
end

class IndexSchemaParser
  def initialize(index_name, schema_file_path, field_definitions, known_elasticsearch_types)
    @index_name = index_name
    @schema_file_path = schema_file_path
    @field_definitions = field_definitions
    @known_elasticsearch_types = known_elasticsearch_types
  end

  def parse
    elasticsearch_type_names = parse_file

    IndexSchema.new(
      @index_name,
      @field_definitions,
      lookup_elasticsearch_types(elasticsearch_type_names),
    )
  end

  def self.parse_all(config_path, field_definitions, known_elasticsearch_types)
    Hash[IndexSchemaParser::index_schema_paths(config_path).map { |index_name, schema_file_path|
      [
        index_name,
        IndexSchemaParser.new(index_name, schema_file_path, field_definitions, known_elasticsearch_types).parse
      ]
    }]
  end

  def self.index_schema_paths(config_path)
    files = Dir.new(File.join(config_path, "indexes")).select do |filename|
      filename =~ /\A[a-z][-a-z]*\.json\z/
    end

    files.map do |filename|
      [
        filename.sub(/.json$/, ""),
        File.join(config_path, "indexes", filename),
      ]
    end
  end

private

  def lookup_elasticsearch_types(elasticsearch_type_names)
    elasticsearch_type_names.map { |elasticsearch_type_name|
      elasticsearch_type = @known_elasticsearch_types[elasticsearch_type_name]
      if elasticsearch_type.nil?
        raise_error %{Unknown document type "#{elasticsearch_type_name}"}
      end
      elasticsearch_type
    }
  end

  def parse_file
    raw = load_json

    elasticsearch_type_names = raw.delete("elasticsearch_types")
    if elasticsearch_type_names.nil?
      raise_error %{Missing "elasticsearch_types"}
    end

    unless raw.empty?
      raise_error %{Unknown keys (#{raw.keys.join(", ")})}
    end

    elasticsearch_type_names
  end

  def raise_error(message)
    raise %{#{message}, in index definition in "#{@schema_file_path}"}
  end

  def load_json
    JSON.parse(File.read(@schema_file_path, encoding: "UTF-8"))
  end
end
