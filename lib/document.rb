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
        doc.__send__ "#{key}=", hash[key.to_s]
      end
    }
  end
end

class Document < Link
  auto_keys :title, :link, :description, :format, :indexable_content
  attr_accessor :additional_links

  def self.from_hash(hash)
    super.tap { |doc|
      doc.additional_links =
        (hash["additional_links"] || []).map { |h| Link.from_hash(h) }
    }
  end
end
