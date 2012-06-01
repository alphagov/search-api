require 'active_support/core_ext/string/inflections'
require 'gds_api/panopticon'
require 'plek'

class PopularItems
  attr_accessor :items

  def initialize(logger = nil)
    publisher = GdsApi::Panopticon.new(Plek.current.environment)
    @items = publisher.curated_lists || [] # TODO: is this the best place?
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
