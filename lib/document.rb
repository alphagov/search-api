class Document

  attr_reader :es_score

  def initialize(field_names, attributes = {}, es_score = nil)
    @field_names = field_names.map(&:to_s)
    @attributes = {}
    @es_score = es_score
    update_attributes!(attributes)
  end

  def self.from_hash(hash, mappings, es_score = nil)
    type = hash["_type"] || "edition"
    field_names = mappings[type]["properties"].keys.map(&:to_s)
    self.new(field_names, hash, es_score)
  end

  def update_attributes!(attributes)
    attributes.each do |key, value|
      self.set(key, value)
    end
  end

  def has_field?(field_name)
    @field_names.include?(field_name.to_s)
  end

  def get(key)
    @attributes[key.to_s]
  end

  def set(key, value)
    if has_field?(key)
      @attributes[key.to_s] = value
    end
  end

  def weighted(factor)
    weighted_score = @es_score ? @es_score * factor : nil
    Document.new(@field_names, @attributes, weighted_score)
  end

  def elasticsearch_export
    Hash.new.tap do |doc|
      @field_names.each do |key|
        value = get(key)
        if value.is_a?(Array)
          value = value.map {|v| v.is_a?(Document) ? v.elasticsearch_export : v }
        end
        unless value.nil? or (value.respond_to?(:empty?) and value.empty?)
          doc[key] = value
        end
      end
      doc["_type"] = "edition"
    end
  end

  def to_hash
    field_values = Hash[@field_names.map { |key|
      value = get(key)
      if value.is_a?(Array)
        value = value.map { |v| v.is_a?(Document) ? v.to_hash : v }
      end
      [key.to_s, value]
    }.select{ |key, value|
      ![nil, []].include?(value)
    }]

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

  def respond_to_missing?(method_name, include_private)
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
