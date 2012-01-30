require "delsolr"

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

  auto_keys :title, :link, :description, :format, :section, :subsection,
    :indexable_content, :additional_links, :boost_phrases
  attr_writer :highlight

  def self.from_hash(hash)
    hash = unflatten(hash)
    super(hash).tap { |doc|
      doc.additional_links =
        lookup(hash, :additional_links, []).map { |h| Link.from_hash(h) }.sort_by { |l| l.link_order }
    }
  end

  FORMAT_TRANSLATION = {
    "planner" => "answer",
    "smart_answer" => "answer",
    "calculator" => "answer"
  }

  def presentation_format
    FORMAT_TRANSLATION.fetch(format, format)
  end

  def highlight
    @highlight || description
  end
end
