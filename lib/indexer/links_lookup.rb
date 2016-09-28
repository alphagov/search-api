require 'services'

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

      doc_hash.merge(taggings_with_slugs(links))
    end

  private

    # Some applications send the `content_id` for their items. This means we can
    # skip the lookup from the publishing-api.
    def find_content_id(doc_hash)
      if doc_hash["content_id"].present?
        doc_hash["content_id"]
      else
        GdsApi.with_retries(maximum_number_of_attempts: 5) do
          Services.publishing_api.lookup_content_id(base_path: doc_hash["link"])
        end
      end
    end

    def find_links(content_id)
      begin
        GdsApi.with_retries(maximum_number_of_attempts: 5) do
          Services.publishing_api.get_expanded_links(content_id)['expanded_links']
        end
      rescue GdsApi::TimedOutException => e
        @logger.error("Timeout fetching expanded links for #{content_id}")
        raise e
      end
    end

    # Documents in rummager currently reference topics, browse pages and
    # organisations by "slug", a concept that exists in Publisher and Whitehall.
    # It does not exist in the publishing-api, so we need to infer the slug
    # from the base path.
    def taggings_with_slugs(links)
      links_with_slugs = {}

      # We still call topics "specialist sectors" in rummager.
      links_with_slugs["specialist_sectors"] = links["topics"].to_a.map do |content_item|
        content_item['base_path'].sub('/topic/', '')
      end

      links_with_slugs["mainstream_browse_pages"] = links["mainstream_browse_pages"].to_a.map do |content_item|
        content_item['base_path'].sub('/browse/', '')
      end

      links_with_slugs["organisations"] = links["organisations"].to_a.map do |content_item|
        content_item['base_path'].sub('/government/organisations/', '').sub('/courts-tribunals/', '')
      end

      links_with_slugs["taxons"] = links["taxons"].to_a.map do |content_item|
        content_item['content_id']
      end

      links_with_slugs
    end
  end
end
