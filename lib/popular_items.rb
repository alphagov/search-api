require 'active_support/core_ext/string/inflections'

class PopularItems
  attr_accessor :items
  
  def initialize(filename, logger = nil)
    @items = load(filename)
    @logger = logger || NullLogger.instance
  end
  
  def load(filename)
    items = {}
    section = nil
    File.open(filename, 'r').each do |line|
      if line =~ /^$/
        next
      elsif line =~ /^  /
        title, format, slug = line.strip.split("\t")
        items[section] ||= []
        items[section] << slug
      else
        section = line.strip.parameterize
      end
    end
    items
  end
  
  def popular?(section, slug)
    @items[section] && @items[section].include?(slug)
  end
  
  def link_to_slug(link)
    if link.match(%r{^/([^/]*)(/|$)})
      $1
    end
  end
  
  def select_from(section, solr_results)
    solr_results.select do |r| 
      popular?(section, link_to_slug(r.link))
    end
  end
end
