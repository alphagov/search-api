require "active_support/inflector"

class SearchIndexEntry
  def initialize(field_names, attributes = {})
    @field_names = field_names.map(&:to_s) + ["es_score"]
    @attributes = {}
    update_attributes!(attributes)
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

  def elasticsearch_export
    Hash.new.tap do |doc|
      @field_names.each do |key|
        value = get(key)
        if value.is_a?(Array)
          value = value.map {|v| v.is_a?(SearchIndexEntry) ? v.elasticsearch_export : v }
        end
        unless value.nil? or (value.respond_to?(:empty?) and value.empty?)
          doc[key] = value
        end
      end
      doc["_type"] = "edition"
    end
  end

  def to_hash
    Hash[@field_names.map { |key|
      value = get(key)
      if value.is_a?(Array)
        value = value.map { |v| v.is_a?(SearchIndexEntry) ? v.to_hash : v }
      end
      [key.to_s, value]
    }.select{ |key, value|
      ![nil, []].include?(value)
    }]
  end

  def self.unflatten(hash)
  # Convert from a hash of the form:
  #   {foo__key1: [1, 2, 3], foo__key2: [4, 5, 6]}
  # to the form:
  #   {foo: [{key1: 1, key2: 4}, {key1: 2, key2: 5}, {key1: 3, key2: 6}]}
  #
  # This is useful for deserialising additional link information
   {}.tap { |result|
      hash.each do |k, v|
        lhs, rhs = k.to_s.split(/__/)
        if rhs
          result[lhs] ||= v.length.times.map { {} }
          v.each_with_index do |vv, i|
            result[lhs][i][rhs] = vv
          end
        else
          result[lhs] = v
        end
      end
    }
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

class Link < SearchIndexEntry

  def initialize(attributes)
    super([:title, :link, :link_order], attributes)
  end

  def update_attributes!(attributes)
    super
    self.set(:link_order, attributes[:link_order] || attributes["link_order"] || 0)
  end
end

class Document < SearchIndexEntry

  attr_reader :additional_links
  attr_writer :highlight

  def self.from_hash(hash, mappings)
    field_names = mappings["edition"]["properties"].keys.map(&:to_s)
    self.new(field_names, unflatten(hash))
  end

  def update_attributes!(attributes)
    super(attributes)
    assign_additional_links_from(attributes)
  end

  # The `additional_links` field was originally used in parted content (guides,
  # benefits) to display links to the individual parts. We're not displaying
  # these links any more in the search results, nor are we submitting them to
  # Rummager. In time, they are likely to disappear entirely, taking large
  # tracts of code with them.

  def assign_additional_links_from(attributes)
    additional_links_attributes = attributes[:additional_links] || attributes["additional_links"] || []
    @additional_links = additional_links_attributes.map { |h| Link.new(h) }.sort_by { |l| l.link_order }
  end

  def to_hash
    if additional_links.any?
      super.merge("additional_links" => additional_links.map(&:to_hash))
    else
      super
    end
  end

  PRESENTATION_FORMAT_TRANSLATION = {
    "planner" => "answer",
    "smart_answer" => "answer",
    "calculator" => "answer",
    "licence_finder" => "answer",
    "custom_application" => "answer",
    "calendar" => "answer"
  }

  FORMAT_NAME_ALTERNATIVES = {
    "programme" => "Benefits & credits",
    "transaction" => "Services",
    "local_transaction" => "Services",
    "place" => "Services",
    "answer" => "Quick answers",
    "specialist_guidance" => "Specialist guidance"
  }

  def presentation_format
    PRESENTATION_FORMAT_TRANSLATION.fetch(normalized_format, normalized_format)
  end

  def humanized_format
    FORMAT_NAME_ALTERNATIVES[presentation_format] || presentation_format.humanize.pluralize
  end

  def highlight
    @highlight || description
  end

  private

  def normalized_format
    self.format ? self.format.gsub("-", "_") : "unknown"
  end
end
