module GovukIndex
  class ExpandedLinksPresenter
    def initialize(expanded_links)
      @expanded_links = expanded_links || {}
    end

    def mainstream_browse_page_content_ids
      content_ids("mainstream_browse_pages")
    end

    def organisations
      organisation_slugs("organisations")
    end

    def organisation_content_ids
      content_ids("organisations")
    end

    def people
      slugs("people", "/government/people/")
    end

    def policy_groups
      slugs("working_groups", "/government/groups/")
    end

    def primary_publishing_organisation
      organisation_slugs("primary_publishing_organisation")
    end

    def taxons
      content_ids("taxons")
    end

    def facet_groups
      content_ids("facet_groups")
    end

    def facet_values
      content_ids("facet_values")
    end

    def and_facet_values
      content_ids("facet_values")
    end

    def topic_content_ids
      content_ids("topics")
    end

    def topical_events
      slugs("topical_events", "/government/topical-events/")
    end

    def specialist_sectors
      slugs("topics", "/topic/")
    end

    def mainstream_browse_pages
      slugs("mainstream_browse_pages", "/browse/")
    end

    def part_of_taxonomy_tree
      expanded_links.fetch("taxons", {}).flat_map do |taxon_hash|
        parts_of_taxonomy(taxon_hash)
      end
    end

    def world_locations
      expanded_links.fetch("world_locations", {}).map do |world_location|
        world_location.fetch("title").parameterize
      end
    end

    def default_news_image
      organisation = expanded_links.fetch("primary_publishing_organisation", [])
      organisation[0].dig("details", "default_news_image", "url") unless organisation.empty?
    end

  private

    attr_reader :expanded_links

    def expanded_links_item(key)
      expanded_links[key] || {}
    end

    def values_from_collection(collection, key)
      collection.map { |item| item[key] }
    end

    def content_ids(collection)
      values_from_collection(expanded_links_item(collection), "content_id")
    end

    def slugs(type, path_prefix)
      expanded_links_item(type).map do |content_item|
        content_item["base_path"].gsub(%r{^#{path_prefix}}, "")
      end
    end

    def organisation_slugs(type)
      expanded_links_item(type).map do |content_item|
        content_item["base_path"].sub("/government/organisations/", "").sub("/courts-tribunals/", "")
      end
    end

    def parts_of_taxonomy(taxon_hash)
      parents = [taxon_hash["content_id"]]

      direct_parents = direct_parent_taxons(taxon_hash)

      while direct_parents && !direct_parents.empty?
        # There should not be more than one parent for a taxon. If there is,
        # make an arbitrary choice.
        direct_parent = direct_parents.first

        parents << direct_parent["content_id"]

        direct_parents = direct_parent_taxons(direct_parent)
      end

      parents.reverse
    end

    def direct_parent_taxons(taxon)
      taxon.dig("links", "parent_taxons") ||
        taxon.dig("links", "root_taxon") ||
        []
    end
  end
end
