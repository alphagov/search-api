class IndexSchema
  attr_reader :name, :opensearch_types

  def initialize(name, field_definitions, opensearch_types)
    @name = name
    @opensearch_types = Hash[opensearch_types.map do |opensearch_type|
      [opensearch_type.name, opensearch_type]
    end]
    @document_type_field = field_definitions["document_type"][:es_config]
  end

  def es_mappings
    properties = {
      "document_type" => @document_type_field,
    }
    @opensearch_types.each_value do |value|
      properties = properties.merge(value.es_config)
    end
    { "properties" => properties }
  end

  def opensearch_type(opensearch_type_name)
    @opensearch_types[opensearch_type_name]
  end
end

class IndexSchemaParser
  def initialize(index_name, schema_file_path, field_definitions, known_opensearch_types)
    @index_name = index_name
    @schema_file_path = schema_file_path
    @field_definitions = field_definitions
    @known_opensearch_types = known_opensearch_types
  end

  def parse
    opensearch_type_names = parse_file

    IndexSchema.new(
      @index_name,
      @field_definitions,
      lookup_opensearch_types(opensearch_type_names),
    )
  end

  def self.parse_all(config_path, field_definitions, known_opensearch_types)
    Hash[IndexSchemaParser.index_schema_paths(config_path).map do |index_name, schema_file_path|
      [
        index_name,
        IndexSchemaParser.new(index_name, schema_file_path, field_definitions, known_opensearch_types).parse,
      ]
    end]
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

  def lookup_opensearch_types(opensearch_type_names)
    opensearch_type_names.map do |opensearch_type_name|
      opensearch_type = @known_opensearch_types[opensearch_type_name]
      if opensearch_type.nil?
        raise_error %(Unknown document type "#{opensearch_type_name}")
      end
      opensearch_type
    end
  end

  def parse_file
    raw = load_json

    opensearch_type_names = raw.delete("opensearch_types")
    if opensearch_type_names.nil?
      raise_error %(Missing "opensearch_types")
    end

    unless raw.empty?
      raise_error %{Unknown keys (#{raw.keys.join(', ')})}
    end

    opensearch_type_names
  end

  def raise_error(message)
    raise %(#{message}, in index definition in "#{@schema_file_path}")
  end

  def load_json
    JSON.parse(File.read(@schema_file_path, encoding: "UTF-8"))
  end
end
