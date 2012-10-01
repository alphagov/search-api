require 'gds_api/panopticon'
require 'plek'

class PopularItems
  attr_accessor :items

  def initialize(panopticon_api_credentials, logger = nil)
    publisher = GdsApi::Panopticon.new(Plek.current_env, panopticon_api_credentials)
    begin
      @items = publisher.curated_lists || {}
    rescue NoMethodError  # HACK HACK HACK, but it's being deleted imminently
      @items = {}
    end
    @logger = logger || NullLogger.instance
  end

  def select_from(section, solr_results)
    (@items[section] || []).map do |slug|
      solr_results.find { |result| link_to_slug(result.link) == slug }
    end.reject(&:nil?)
  end

private
  def link_to_slug(link)
    if link.match(%r{^/([^/]*)(/|$)})
      $1
    end
  end
end
