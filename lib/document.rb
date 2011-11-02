require "delsolr"

class Link
  def self.auto_keys(*names)
    attr_accessor *names
    @auto_keys ||= []
    @auto_keys += names
  end

  auto_keys :title, :link

  def self.from_hash(hash)
    new.tap { |doc|
      @auto_keys.each do |key|
        doc.set key, hash[key.to_s]
      end
    }
  end

  def get(key)
    __send__ key
  end

  def set(key, value)
    __send__ "#{key}=", value
  end
end

class Document < Link

  INDEXED_FIELDS = [:title, :link, :description, :format, :indexable_content]
  auto_keys *INDEXED_FIELDS
  attr_accessor :additional_links

  def self.from_hash(hash)
    super.tap { |doc|
      doc.additional_links =
        (hash["additional_links"] || []).map { |h| Link.from_hash(h) }
    }
  end

  def solr_export(solr_document=DelSolr::Document.new)
    solr_document.tap { |doc|
      INDEXED_FIELDS.each do |field|
        value = get(field)
        doc.add_field(field.to_s, value) if value
      end
    }
  end
end
