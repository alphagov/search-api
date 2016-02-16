require_relative "../app"
require 'gds_api/publishing_api_v2'

class IndexDocuments
  MIGRATED_TAGGING_APPS = %w{
    businesssupportfinder
    calculators
    calendars
    collections-publisher
    hmrc-manuals-api
    licencefinder
    policy-publisher
    smartanswers
  }

  def process(message)
    index_links_from_message(message)
    message.ack
  end

private

  def index_links_from_message(message)
    return unless publishing_app_migrated?(message)
    raw_links = links_from_payload(message)

    unless raw_links.empty?
      links = rummager_fields_from_links(raw_links)
      base_path = document_base_path(message)
      update_index(base_path, links)
    end
  end

  def publishing_app_migrated?(message)
    MIGRATED_TAGGING_APPS.include? message.payload["publishing_app"]
  end

  def links_from_payload(message)
    message.payload.fetch("links", {})
  end

  def rummager_fields_from_links(links)
    results = {}
    rummager_field_mappers.each { |field_name, mapper|
      field_values = mapper.call(links)
      if field_values
        results[field_name] = field_values
      end
    }
    results
  end

  def rummager_field_mappers
    {
      "mainstream_browse_pages" => lambda { |links| sorted_link_paths(links, "mainstream_browse_pages") },
      "organisations" => lambda { |links| (sorted_link_paths(links, "lead_organisations") + sorted_link_paths(links, "organisations")).uniq },
      "specialist_sectors" => lambda { |links| sorted_link_paths(links, "topics") },
    }
  end

  def sorted_link_paths(links, link_types)
    links.fetch(link_types, []).map { |content_id| base_path(content_id) }.compact.sort
  end

  def document_base_path(message)
    message.payload.fetch("base_path")
  end

  def base_path(content_id)
    publishing_api.get_content(content_id)["base_path"]
  end

  def update_index(base_path, links)
    indices_with_base_path(base_path).map do |index|
      begin
        index.amend(base_path, links)
      rescue Elasticsearch::DocumentNotFound => e
        Airbrake.notify_or_ignore(e)
      end
    end
  end

  def indices_with_base_path(document_base_path)
    indices_to_search = search_server.index_for_search(search_config.content_index_names)
    results = indices_to_search.raw_search(query: {term: {link: document_base_path}})

    indices = results["hits"]["hits"].map do |hit|
      index = Elasticsearch::Index.strip_alias_from_index_name(hit["_index"])
      search_server.index(index) if index
    end
  end

  def publishing_api
    @publishing_api ||= GdsApi::PublishingApiV2.new(
      Plek.new.find('publishing-api'),
      bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example'
    )
  end

  def search_server
    @search_server ||= search_config.search_server
  end

  def search_config
    @search_config ||= Rummager.settings.search_config
  end
end
