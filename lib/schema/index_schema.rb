require "json"
require "schema/document_types"

class IndexSchema
  attr_reader :name

  def initialize(name, document_types)
    @name = name
    @document_types = Hash[document_types.map { |document_type|
      [document_type.name, document_type]
    }]
  end

  def es_mappings
    @document_types.reduce({}) { |mappings, (type_name, document_type)|
      mappings[type_name] = {
        "properties" => document_type.es_config
      }
      mappings
    }
  end

  def document_type(document_type_name)
    @document_types[document_type_name]
  end
end

class IndexSchemaParser
  def initialize(index_name, schema_file_path, known_document_types)
    @index_name = index_name
    @schema_file_path = schema_file_path
    @known_document_types = known_document_types
  end

  def parse
    document_type_names = parse_file

    IndexSchema.new(
      @index_name,
      lookup_document_types(document_type_names),
    )
  end

  def self.parse_all(config_path)
    known_document_types = DocumentTypesParser.new(config_path).parse
    Hash[IndexSchemaParser::index_schema_paths(config_path).map { |index_name, schema_file_path|
      [
        index_name,
        IndexSchemaParser.new(index_name, schema_file_path, known_document_types).parse
      ]
    }]
  end

private

  def lookup_document_types(document_type_names)
    document_type_names.map { |document_type_name|
      document_type = @known_document_types[document_type_name]
      if document_type.nil?
        raise_error %{Unknown document type "#{document_type_name}"}
      end
      document_type
    }
  end

  def parse_file
    raw = load_json

    document_type_names = raw.delete("document_types")
    if document_type_names.nil?
      raise_error %{Missing "document_types"}
    end

    unless raw.empty?
      raise_error %{Unknown keys (#{raw.keys.join(", ")})}
    end

    document_type_names
  end

  def raise_error(message)
    raise %{#{message}, in index definition in "#{@schema_file_path}"}
  end

  def load_json
    JSON.parse(File.read(@schema_file_path, encoding: 'UTF-8'))
  end

  def self.index_schema_paths(config_path)
    Dir.new(File.join(config_path, "indexes")).select { |filename|
      filename =~ /\A[a-z]+(_[a-z]+)*\.json\z/
    }.map { |filename|
      [
        filename.sub(/.json$/, ''),
        File.join(config_path, "indexes", filename),
      ]
    }
  end
end
