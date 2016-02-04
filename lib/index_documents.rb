require_relative "../app"
require 'gds_api/publishing_api_v2'

class IndexDocuments
  def process(message)
    raw_links = links_from_payload(message)

    if !raw_links.nil? && !raw_links.empty?
      links = remap_keys(raw_links, content_tagger_to_rummager_map)
      links.each do |(link_type, content_ids)|
        links[link_type] = paths_from_content_ids(content_ids)
      end

      base_path = document_base_path(message)
      update_index(base_path, links)
    end

    message.ack
  end

private
  def links_from_payload(message)
    message.payload["links"].try(:slice, *content_tagger_tags)
  end

  def paths_from_content_ids(content_ids)
    content_ids.map { |content_id| base_path content_id }.compact.sort
  end

  def content_tagger_tags
    %w{
      mainstream_browse_page
      parent
      topics
      organisations
    }
  end

  def content_tagger_to_rummager_map
    {
      "topics" => "specialist_sectors",
      "organisations" => "lead_organisations",
      "mainstream_browse_page" => "mainstream_browse_pages",
      "parent" => "parent",
    }
  end

  def remap_keys(hash, keymap)
    Hash[hash.map {|k, v| [keymap[k], v] }]
  end

  def document_base_path(message)
    message.payload["base_path"]
  end

  def base_path(content_id)
    GdsApi::PublishingApiV2.new(Plek.current.find('publishing-api')).get_content(content_id)["base_path"]
  end

  def update_index(base_path, links)
    indices_with_base_path(base_path).map do |index|
      index.amend(base_path, links)
    end
  end

  def indices_with_base_path(document_base_path)
    indices_to_search = search_server.index_for_search(search_config.content_index_names)
    results = indices_to_search.raw_search(query: {term: {link: document_base_path}})

    indices = results["hits"]["hits"].map do |hit|
      Elasticsearch::Index.strip_alias_from_index_name(hit["_index"])
    end

    indices.map do |index|
      search_server.index(index)
    end
  end

  def search_server
    @search_server ||= search_config.search_server
  end

  def search_config
    @search_config ||= Rummager.settings.search_config
  end
end
