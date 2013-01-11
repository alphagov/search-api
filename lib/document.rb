require "active_support/inflector"

class Link

  def self.auto_keys(*names)
    @auto_keys ||= []
    names.each do |name|
      next if @auto_keys.include?(name)
      attr_accessor name
      @auto_keys << name
    end
    @auto_keys
  end

  auto_keys :title, :link, :link_order

  def self.from_hash(hash)
    new.tap { |doc|
      auto_keys.each do |key|
        doc.set key, lookup(hash, key)
      end
      doc.set 'link_order', lookup(hash, 'link_order', 0)
    }
  end

  def self.lookup(hash, sym, default=nil)
    hash[sym] || hash[sym.to_s] || default
  end

  def get(key)
    __send__ key
  end

  def set(key, value)
    __send__ "#{key}=", value
  end

  def elasticsearch_export
    Hash.new.tap do |doc|
      self.class.auto_keys.each do |key|
        value = get(key)
        if value.is_a?(Array)
          value = value.map {|v| v.is_a?(Link) ? v.elasticsearch_export : v }
        end
        unless value.nil? or (value.respond_to?(:empty?) and value.empty?)
          doc[key] = value
        end
      end
      doc[:_type] = "edition"
    end
  end

  def to_hash
    Hash[self.class.auto_keys.map { |key|
      value = get(key)
      if value.is_a?(Array)
        value = value.map { |v| v.is_a?(Link) ? v.to_hash : v }
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
end

class Document < Link

  # The `additional_links` field was originally used in parted content (guides,
  # benefits) to display links to the individual parts. We're not displaying
  # these links any more in the search results, nor are we submitting them to
  # Rummager. In time, they are likely to disappear entirely, taking large
  # tracts of code with them.

  auto_keys :title, :link, :description, :format, :section, :subsection, :subsubsection,
    :indexable_content, :additional_links
  attr_writer :highlight

  def self.from_hash(hash)
    auto_keys(*hash.keys.map(&:to_sym))
    hash = unflatten(hash)
    super(hash).tap { |doc|
      doc.additional_links =
        lookup(hash, :additional_links, []).map { |h| Link.from_hash(h) }.sort_by { |l| l.link_order }
    }
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
    format ? format.gsub("-", "_") : 'unknown'
  end
end
