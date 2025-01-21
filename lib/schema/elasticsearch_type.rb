class ElasticsearchType
  attr_reader :name, :fields

  def initialize(name, fields)
    @name = name
    @fields = fields
  end

  def es_config
    fields_to_hash = @fields.map do |field_name, field|
      [field_name, field.es_config]
    end
    Hash[fields_to_hash]
  end
end

class ElasticsearchTypeParser
  attr_reader :file_path, :base_type, :field_definitions

  def initialize(file_path, base_type, field_definitions)
    @file_path = file_path
    @base_type = base_type
    @field_definitions = field_definitions
  end

  def parse
    field_names, use_base_type = parse_file

    unless base_type.nil? || !use_base_type
      field_names = merge_field_names(field_names)
    end

    fields = Hash[field_names.map do |field_name|
      field_definition = field_definitions.fetch(field_name) do
        raise_error(%(Undefined field "#{field_name}"))
      end
      [field_name, field_definition]
    end]

    ElasticsearchType.new(type_name, fields)
  end

private

  def type_name
    File.basename(file_path).sub(/.json$/, "")
  end

  def raise_error(message)
    raise %(#{message}, in document type definition in "#{file_path}")
  end

  def load_json
    JSON.parse(File.read(file_path, encoding: "UTF-8"))
  end

  def parse_file
    raw = load_json

    use_base_type = raw.delete("use_base_type") { true }

    fields = raw.delete("fields")
    if fields.nil?
      raise_error %(Missing "fields")
    end
    if fields != fields.uniq
      raise_error %(Duplicate entries in "fields")
    end

    unless raw.empty?
      raise_error %{Unknown keys (#{raw.keys.join(', ')})}
    end

    [fields, use_base_type]
  end

  def merge_field_names(field_names)
    ((field_names || []) + base_type.fields.keys).uniq
  end
end

class ElasticsearchTypesParser
  attr_reader :config_path

  def initialize(config_path, field_definitions)
    @config_path = config_path
    @field_definitions = field_definitions
  end

  def parse
    parsed_arr = elasticsearch_type_paths.map do |elasticsearch_type, file_path|
      [
        elasticsearch_type,
        ElasticsearchTypeParser.new(file_path, base_type, @field_definitions).parse,
      ]
    end
    Hash[parsed_arr]
  end

private

  def base_type
    @base_type ||= ElasticsearchTypeParser.new(
      File.join(config_path, "base_elasticsearch_type.json"),
      nil,
      @field_definitions,
    ).parse
  end

  def elasticsearch_type_paths
    files = Dir.new(File.join(config_path, "elasticsearch_types"))

    json_files = files.select do |filename|
      filename =~ /\A[a-z][-_a-z]*\.json\z/
    end

    json_files.map do |filename|
      [
        filename.sub(/.json$/, ""),
        File.join(config_path, "elasticsearch_types", filename),
      ]
    end
  end

  def elasticsearch_type_raw
    files.each.with_object({}) do |filename, doctypes|
      doctype = filename.split(".").first
      doctypes[doctype] = load_doctype(filename)
    end
  end
end
