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

    def primary_publishing_organisation
      organisation_slugs("primary_publishing_organisation")
    end

    def taxons
      content_ids("taxons")
    end

    def topic_content_ids
      content_ids("topics")
    end

    def specialist_sectors
      expanded_links_item("topics").map do |content_item|
        content_item["base_path"].sub("/topic/", "")
      end
    end

    def mainstream_browse_pages
      expanded_links_item("mainstream_browse_pages").map do |content_item|
        content_item["base_path"].sub("/browse/", "")
      end
    end

    def part_of_taxonomy_tree
      expanded_links.fetch("taxons", {}).flat_map do |taxon_hash|
        parts_of_taxonomy(taxon_hash)
      end
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

    def organisation_slugs(type)
      expanded_links_item(type).map do |content_item|
        content_item["base_path"].sub("/government/organisations/", "").sub("/courts-tribunals/", "")
      end
    end

    def parts_of_taxonomy(taxon_hash)
      parents = [taxon_hash["content_id"]]

      direct_parents = taxon_hash.dig("links", "parent_taxons")
      while direct_parents && !direct_parents.empty?
        # There should not be more than one parent for a taxon. If there is,
        # make an arbitrary choice.
        direct_parent = direct_parents.first

        parents << direct_parent["content_id"]

        direct_parents = direct_parent.dig("links", "parent_taxons") || []
      end

      parents.reverse
    end
  end
end
