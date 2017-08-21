module GovukIndex
  class ElasticsearchPresenter
    def initialize(payload:, type:, sanitiser:)
      @payload = payload
      @type = type
      @sanitiser = sanitiser
    end

    def identifier
      {
        _type: type,
        _id: base_path,
        version: payload["payload_version"],
        version_type: "external",
      }
    end

    def document
      {}.merge(common_fields)
        .merge(fields_from_expanded_links)
    end

    def common_fields
      {
        content_id: payload["content_id"],
        content_store_document_type: payload["document_type"],
        description: payload["description"],
        email_document_supertype: payload["email_document_supertype"],
        format: payload["document_type"],
        government_document_supertype: payload["government_document_supertype"],
        indexable_content: sanitiser.clean(payload),
        is_withdrawn: withdrawn?,
        link: base_path,
        navigation_document_supertype: payload["navigation_document_supertype"],
        popularity: calculate_popularity,
        public_timestamp: payload["public_updated_at"],
        publishing_app: payload["publishing_app"],
        rendering_app: payload["rendering_app"],
        title: payload["title"],
        user_journey_document_supertype: payload["user_journey_document_supertype"],
      }
    end

    def fields_from_expanded_links
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

    def base_path
      @_base_path ||= payload["base_path"]
    end

    def valid!
      return if base_path
      raise(ValidationError, "base_path missing from payload")
    end

  private

    attr_reader :payload, :sanitiser, :type

    def withdrawn?
      !payload["withdrawn_notice"].nil?
    end

    def expanded_links
      @_expanded_links ||= payload["expanded_links"] || {}
    end

    def expanded_links_item(key)
      expanded_links[key] || {}
    end

    def taxons
      expanded_links["taxons"] || {}
    end

    def values_from_collection(collection, key)
      collection.map { |item| item[key] }
    end

    def organisation_slugs(type)
      expanded_links_item(type).map do |content_item|
        content_item["base_path"].sub('/government/organisations/', '').sub('/courts-tribunals/', '')
      end
    end

    def specialist_sector_slugs
      expanded_links_item("topics").map do |content_item|
        content_item['base_path'].sub('/topic/', '')
      end
    end

    def mainstream_browse_page_slugs
      expanded_links_item("mainstream_browse_pages").map do |content_item|
        content_item['base_path'].sub('/browse/', '')
      end
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

    def content_ids(collection)
      values_from_collection(expanded_links_item(collection), "content_id")
    end

    def calculate_popularity
      lookup = Indexer::PopularityLookup.new("govuk_index", SearchConfig.instance)
      lookup.lookup_popularities([base_path])[base_path]
    end
  end
end
