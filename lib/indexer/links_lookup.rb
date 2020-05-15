# LinksLookup finds the tags (links) from the publishing-api and merges them into
# the document. If there aren't any links, the payload will be returned unchanged.
module Indexer
  class LinksLookup
    def initialize
      @logger = Logging.logger[self]
    end

    def self.prepare_tags(doc_hash)
      new.prepare_tags(doc_hash)
    end

    def prepare_tags(doc_hash)
      # Rummager contains externals links (that have a full URL in the `link`
      # field). These won't have tags associated with them so we can bail out.
      return doc_hash if doc_hash["link"] =~ /\Ahttps?:\/\//

      # Bail out if the base_path doesn't exist in publishing-api
      content_id = find_content_id(doc_hash)
      return doc_hash unless content_id

      # Bail out if the base_path doesn't exist in publishing-api
      links = find_links(content_id)
      return doc_hash unless links

      doc_hash = doc_hash.merge(taggings_with_slugs(links))
      doc_hash.merge(taggings_with_content_ids(links))
    end

  private

    # Some applications send the `content_id` for their items. This means we can
    # skip the lookup from the publishing-api.
    def find_content_id(doc_hash)
      if doc_hash["content_id"].present?
        doc_hash["content_id"]
      else
        Indexer.find_content_id(doc_hash["link"], @logger)
      end
    end

    def find_links(content_id)
      GdsApi.with_retries(maximum_number_of_attempts: 5) do
        Services.publishing_api.get_expanded_links(content_id)["expanded_links"]
      end
    rescue GdsApi::TimedOutException => e
      @logger.error("Timeout fetching expanded links for #{content_id}")
      GovukError.notify(
        e,
        extra: {
          error_message: "Timeout fetching expanded links",
          content_id: content_id,
        },
      )
      raise Indexer::PublishingApiError
    rescue GdsApi::HTTPNotFound => e
      # If the Content ID no longer exists in the Publishing API, there isn't really much
      # we can do at this point. There doesn't seem to be any compelling reason to record
      # this in Sentry as there is no bug to fix.
      @logger.error("HTTP not found error fetching expanded links for #{content_id}: #{e.message}")
      nil
    rescue GdsApi::HTTPErrorResponse => e
      @logger.error("HTTP error fetching expanded links for #{content_id}: #{e.message}")
      # We capture all GdsApi HTTP exceptions here so that we can send them
      # manually to Sentry. This allows us to control the message and parameters
      # such that errors are grouped in a sane manner.
      GovukError.notify(
        e,
        extra: {
          message: "HTTP error fetching expanded links",
          content_id: content_id,
          error_code: e.code,
          error_message: e.message,
          error_details: e.error_details,
        },
      )
      raise Indexer::PublishingApiError
    end

    # Documents in rummager currently reference topics, browse pages and
    # organisations by "slug", a concept that exists in Publisher and Whitehall.
    # It does not exist in the publishing-api, so we need to infer the slug
    # from the base path.
    def taggings_with_slugs(links)
      links_with_slugs = {}

      # We still call topics "specialist sectors" in rummager.
      links_with_slugs["specialist_sectors"] = links["topics"].to_a.map do |content_item|
        content_item["base_path"].sub("/topic/", "")
      end

      links_with_slugs["mainstream_browse_pages"] = links["mainstream_browse_pages"].to_a.map do |content_item|
        content_item["base_path"].sub("/browse/", "")
      end

      links_with_slugs["organisations"] = links["organisations"].to_a.map do |content_item|
        content_item["base_path"].sub("/government/organisations/", "").sub("/courts-tribunals/", "")
      end

      links_with_slugs["primary_publishing_organisation"] = links["primary_publishing_organisation"].to_a.map do |content_item|
        content_item["base_path"].sub("/government/organisations/", "").sub("/courts-tribunals/", "")
      end

      links_with_slugs["taxons"] = content_ids_for(links, "taxons")

      links_with_slugs
    end

    def taggings_with_content_ids(links)
      {
        "topic_content_ids" => content_ids_for(links, "topics"),
        "mainstream_browse_page_content_ids" => content_ids_for(links, "mainstream_browse_pages"),
        "organisation_content_ids" => content_ids_for(links, "organisations"),
        "facet_groups" => content_ids_for(links, "facet_groups"),
        "facet_values" => content_ids_for(links, "facet_values"),
        "part_of_taxonomy_tree" => parts_of_taxonomy_for_all_taxons(links),
      }
    end

    def parts_of_taxonomy_for_all_taxons(links)
      links.fetch("taxons", []).flat_map do |taxon_hash|
        parts_of_taxonomy(taxon_hash)
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

    def content_ids_for(links, link_type)
      links[link_type].to_a.map do |content_item|
        content_item["content_id"]
      end
    end
  end
end
