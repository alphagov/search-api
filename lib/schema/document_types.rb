require "json"
require "schema/field_definitions"

class DocumentType
  attr_reader :name, :fields, :allowed_values

  def initialize(name, fields, allowed_values)
    @name = name
    @fields = fields
    @allowed_values = allowed_values
  end

  def es_config
    Hash[@fields.map { |field_name, field|
      [field_name, field.es_config]
    }]
  end
end

class DocumentTypeParser
  attr_reader :file_path, :base_type, :field_definitions

  def initialize(file_path, base_type, field_definitions)
    @file_path = file_path
    @base_type = base_type
    @field_definitions = field_definitions
  end

  def parse
    field_names, allowed_values = parse_file

    unless base_type.nil?
      field_names = merge_field_names(field_names)
      unless base_type.allowed_values.empty?
        raise_error %{Specifying `allowed_values` in base document type is not supported}
      end
    end

    fields = Hash[field_names.map { |field_name|
      [field_name, field_definitions.get(field_name)]
    }]

    add_allowed_values_to_field_definitions(fields, allowed_values)

    DocumentType.new(type_name, fields, allowed_values)
  end

private

  def type_name
    File.basename(file_path).sub(/.json$/, "")
  end

  def raise_error(message)
    raise %{#{message}, in document type definition in "#{file_path}"}
  end

  def load_json
    JSON.parse(File.read(file_path, encoding: 'UTF-8'))
  end

  def parse_file
    raw = load_json

    fields = raw.delete("fields")
    if fields.nil?
      raise_error %{Missing "fields"}
    end

    allowed_values = raw.delete("allowed_values") || {}

    unless raw.empty?
      raise_error %{Unknown keys (#{raw.keys.join(", ")})}
    end

    [fields, allowed_values]
  end

  def merge_field_names(field_names)
    ((field_names || []) + base_type.fields.keys).uniq
  end

  def add_allowed_values_to_field_definitions(fields, allowed_values)
    allowed_values.each do |field_name, values|
      if fields[field_name].nil?
        raise_error %{Field "#{field_name}" set in "allowed_values", but not in "fields"}
      end
      field_definition = fields[field_name].clone
      field_definition.allowed_values = values
      fields[field_name] = field_definition
    end
  end
end

class DocumentTypesParser
  attr_reader :config_path

  def initialize(config_path)
    @config_path = config_path
  end

  def parse
    @field_definitions = FieldDefinitions.parse(config_path)

    Hash[document_type_paths.map { |document_type, file_path|
      [
        document_type,
        DocumentTypeParser.new(file_path, base_type, @field_definitions).parse,
      ]
    }]
  end

private

  def base_type
    @base_type ||= DocumentTypeParser.new(
      File.join(config_path, "base_document_type.json"),
      nil,
      @field_definitions,
    ).parse
  end

  def document_type_paths
    Dir.new(File.join(config_path, "document_types")).select { |filename|
      filename =~ /\A[a-z]+(_[a-z]+)*\.json\z/
    }.map { |filename|
      [
        filename.sub(/.json$/, ''),
        File.join(config_path, "document_types", filename),
      ]
    }
  end

  def document_type_raw
    files.each.with_object({}) do |filename, doctypes|
      doctype = filename.split(".").first
      doctypes[doctype] = load_doctype(filename)
    end
  end
end
