require 'services'

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
    #   "specialist_sectors" => ['some/topic-slug'],
    #   "organisations" => ['some-organisation']
    # }
    def rummager_fields_from_links(links)
      browse_pages = sorted_link_paths(links, "mainstream_browse_pages")
      organisations = (sorted_link_paths(links, "lead_organisations") + sorted_link_paths(links, "organisations")).uniq
      specialist_sectors = sorted_link_paths(links, "topics")

      {
        "mainstream_browse_pages" => browse_pages,
        "organisations" => organisations,
        "specialist_sectors" => specialist_sectors,
      }
    end

  private

    def sorted_link_paths(links, link_types)
      links.fetch(link_types, []).map { |content_id| base_path(content_id) }.compact.sort
    end

    def base_path(content_id)
      base_path = Services.publishing_api.get_content!(content_id)["base_path"]
      base_path
        .gsub('/government/organisations/', '')
        .gsub('/topic/', '')
        .gsub('/browse/', '')
    rescue GdsApi::HTTPNotFound, # Items in the links hash may not exist yet.
           GdsApi::HTTPUnauthorized # Items may be access limited.
      nil
    end
  end
end
