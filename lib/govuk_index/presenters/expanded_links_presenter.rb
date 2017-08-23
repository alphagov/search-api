module GovukIndex
  class ExpandedLinksPresenter
    def initialize(expanded_links)
      @expanded_links = expanded_links || {}
    end

    def present
      {
        mainstream_browse_pages: mainstream_browse_page_slugs,
        mainstream_browse_page_content_ids: content_ids("mainstream_browse_pages"),
        organisations: organisation_slugs("organisations"),
        organisation_content_ids: content_ids("organisations"),
        part_of_taxonomy_tree: taxonomy_tree,
        primary_publishing_organisation: organisation_slugs("primary_publishing_organisation"),
        specialist_sectors: specialist_sector_slugs,
        taxons: content_ids("taxons"),
        topic_content_ids: content_ids("topics"),
      }
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

    def specialist_sector_slugs
      expanded_links_item("topics").map do |content_item|
        content_item["base_path"].sub("/topic/", "")
      end
    end

    def mainstream_browse_page_slugs
      expanded_links_item("mainstream_browse_pages").map do |content_item|
        content_item["base_path"].sub("/browse/", "")
      end
    end

    def taxons
      expanded_links["taxons"] || {}
    end

    def taxonomy_tree
      taxons.flat_map { |taxon_hash| parts_of_taxonomy(taxon_hash) }
    end

    def parts_of_taxonomy(taxon_hash)
      parents = [taxon_hash["content_id"]]

      direct_parents = taxon_hash.dig("links", "parent_taxons")
      while !direct_parents.empty?
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
