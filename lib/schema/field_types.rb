require "json"

FieldType = Struct.new("FieldType", :name, :description, :es_config, :multivalued, :children)

class FieldTypes
  def initialize(config_path)
    @config_path = config_path
  end

  def get(type_name)
    @types ||= load_types
    @types.fetch(type_name) do
      raise %{Unknown field type "#{type_name}"}
    end
  end

private

  def load_types
    Hash[load_json.map { |type_name, value|
      es_config = value.delete("es_config")
      if es_config.nil?
        raise %{Missing "es_config" in field type "#{type_name}" in "#{types_file_path}"}
      end

      children = value.delete("children")
      unless [nil, "named", "dynamic"].include? children
        raise %{Invalid value for "children" ("#{children}") in field type "#{type_name}" in "#{types_file_path}"}
      end

      type = FieldType.new(
        type_name,
        value.delete("description") || "",
        es_config,
        value.delete("multivalued") || false,
        children,
      )

      unless value.empty?
        raise %{Unknown keys (#{value.keys.join(", ")}) in field type "#{type_name}" in "#{types_file_path}"}
      end
      [type_name, type]
    }]
  end

  def load_json
    JSON.parse(File.read(types_file_path, encoding: 'UTF-8'))
  end

  def types_file_path
    File.join(@config_path, "field_types.json")
  end
end
