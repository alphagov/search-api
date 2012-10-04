require "delsolr"
require "active_support/inflector"

class Link
  def self.auto_keys(*names)
    @auto_keys ||= []
    if names.any?
      attr_accessor *names
      @auto_keys += names
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

  def solr_export(solr_document=DelSolr::Document.new, prefix="")
    solr_document.tap { |doc|
      self.class.auto_keys.each do |key|
        value = get(key)
        if value.is_a?(Array)
          value.each do |value|
            value.solr_export solr_document, "#{prefix}#{key}__"
          end
        elsif value
          doc.add_field "#{prefix}#{key}", value
        end
      end
    }
  end

  def elasticsearch_export
    Hash.new.tap do |doc|
      self.class.auto_keys.each do |key|
        value = get(key)
        if value.is_a?(Array)
          value = value.map {|v| v.elasticsearch_export }
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
        value = value.map { |v| v.to_hash }
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

  auto_keys :title, :link, :description, :format, :section, :subsection,
    :indexable_content, :additional_links
  attr_writer :highlight

  def self.from_hash(hash)
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

  def presentation_format
    PRESENTATION_FORMAT_TRANSLATION.fetch(normalized_format, normalized_format)
  end

  def humanized_format
    settings.format_name_alternatives[presentation_format] || presentation_format.humanize.pluralize
  end

  def highlight
    @highlight || description
  end

  private

  def normalized_format
    format ? format.gsub("-", "_") : 'unknown'
  end
end
