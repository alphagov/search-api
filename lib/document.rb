class Document
  attr_reader :es_score

  def initialize(field_definitions, attributes = {}, es_score = nil)
    @field_definitions = field_definitions
    @attributes = {}
    @es_score = es_score
    update_attributes!(attributes)
    @id = attributes["_id"]
    @type = attributes.fetch("document_type", attributes["_type"])
  end

  def self.from_hash(hash, elasticsearch_types, es_score = nil)
    type = hash.fetch("document_type", hash["_type"])
    if type.nil?
      raise "Missing elasticsearch type"
    end

    doc_type = elasticsearch_types[type]
    if doc_type.nil?
      raise "Unexpected elasticsearch type '#{type}'. Document types must be configured"
    end

    self.new(doc_type.fields, hash, es_score)
  end

  def update_attributes!(attributes)
    attributes.each do |key, value|
      self.set(key, value)
    end
  end

  def has_field?(field_name)
    @field_definitions.include?(field_name.to_s)
  end

  def get(field_name)
    field_name = field_name.to_s
    values = @attributes[field_name]
    # Convert to array for consistency between elasticsearch 0.90 and 1.0.
    # When we no longer support elasticsearch <1.0, values in @attributes will
    # always be arrays.
    if values.nil?
      values = []
    elsif !values.is_a?(Array)
      values = [values]
    end
    if @field_definitions[field_name].type.multivalued
      values
    else
      values.first
    end
  end

  def set(field_name, value)
    field_name = field_name.to_s
    if has_field?(field_name)
      if value.is_a?(Array) && value.size > 1 && !@field_definitions[field_name].type.multivalued
        raise "Multiple values supplied for '#{field_name}' which is a single-valued field"
      end

      @attributes[field_name] = value
    end
  end

  def elasticsearch_export
    Hash.new.tap do |doc|
      @field_definitions.keys.each do |key|
        value = get(key)
        if value.is_a?(Array)
          value = value.map { |v| v.is_a?(Document) ? v.elasticsearch_export : v }
        end
        unless value.nil? || (value.respond_to?(:empty?) && value.empty?)
          doc[key] = value
        end
      end
      doc["document_type"] = @type
      doc["_type"] = "generic-document"
      doc["_id"] = @id if @id
    end
  end

  def to_hash
    definitions_and_values = @field_definitions.keys.map do |field_name|
      value = get(field_name)

      if value.is_a?(Array)
        value = value.map { |v| v.is_a?(Document) ? v.to_hash : v }
      else
        value = value.is_a?(Document) ? value.to_hash : value
      end

      [field_name.to_s, value]
    end

    without_empty_values = definitions_and_values.select do |_, value|
      ![nil, []].include?(value)
    end

    field_values = Hash[without_empty_values]

    if es_score
      field_values.merge("es_score" => es_score)
    else
      field_values
    end
  end

  def method_missing(method_name, *args)
    if valid_assignment_method?(method_name)
      raise ArgumentError, "wrong number of arguments #{args.count} for 1" unless args.size == 1

      set(field_name_of_assignment_method(method_name), args[0])
    elsif has_field?(method_name)
      get(method_name)
    else
      super
    end
  end

  def respond_to_missing?(method_name, _include_private)
    valid_assignment_method?(method_name) || has_field?(method_name)
  end

private

  def is_assignment?(method_name)
    method_name.to_s[-1] == "="
  end

  def valid_assignment_method?(method_name)
    is_assignment?(method_name) && has_field?(field_name_of_assignment_method(method_name))
  end

  def field_name_of_assignment_method(method_name)
    method_name.to_s[0...-1]
  end
end
