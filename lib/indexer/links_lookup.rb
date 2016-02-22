require 'gds_api/publishing_api_v2'

module Indexer
  class LinksLookup
    # Given a "links hash" from the publishing-api, return a hash of links in
    # "rummager-style". For example:
    #
    # {
    #  "mainstream_browse_pages" => ["953a0469-1284-48ef-932f-354cc7099e7e"],
    #  "topics" => ["974a8fdc-3306-4dd5-b349-34dc00b12ac2"]
    # }
    #
    # is turned into:
    #
    # {
    #   "mainstream_browse_pages" => ['some/browse-slug'],
    #   "specialist_sectors" => ['some/topic-slug']
    # }
    def rummager_fields_from_links(links)
      results = {}
      rummager_field_mappers.each do |field_name, mapper|
        field_values = mapper.call(links)
        if field_values
          results[field_name] = field_values
        end
      end
      results
    end

  private

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

    def base_path(content_id)
      base_path = publishing_api.get_content!(content_id)["base_path"]
      base_path
        .gsub('/government/organisations/', '')
        .gsub('/topic/', '')
        .gsub('/browse/', '')
    rescue GdsApi::HTTPNotFound
      # Content items in the links hash may not exist yet.
      nil
    end

    def publishing_api
      @publishing_api ||= GdsApi::PublishingApiV2.new(
        Plek.new.find('publishing-api'),
        bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example'
      )
    end
  end
end
