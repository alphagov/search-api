require 'services'

module Indexer
  class TagLookup
    def self.prepare_tags(doc_hash)
      new.prepare_tags(doc_hash)
    end

    def prepare_tags(doc_hash)
      # Rummager contains externals links (that have a full URL in the `link`
      # field). These won't have tags associated with them so we can bail out.
      return doc_hash if doc_hash["link"] =~ /\Ahttps?:\/\//

      artefact = find_document_from_content_api(doc_hash["link"])
      return doc_hash unless artefact
      add_tags_from_artefact(artefact, doc_hash)
      add_self_links(doc_hash)
    end

  private

    def find_document_from_content_api(link)
      link_without_trailing_slash = link.sub(/\A\//, '')
      begin
        Services.content_api.artefact!(link_without_trailing_slash)
      rescue GdsApi::HTTPNotFound, GdsApi::HTTPGone
        nil
      end
    end

    def add_self_links(doc_hash)
      # Consider an organisation page to linked to itself.
      # This means that when filtering on an organisation,
      # the organisation page gets included in the search results.
      #
      # This deliberately doesn't match up with the canonical representation
      # of the organisation in the publishing api, since self-linking has
      # a very fuzzy meaning: ids in links can mean both the thing (HMRC)
      # and the content representing the thing (the HMRC home page).
      if doc_hash["format"] == "organisation" && doc_hash["slug"]
        doc_hash["organisations"] << doc_hash["slug"]
        doc_hash["organisations"].uniq!
      end

      doc_hash
    end

    def add_tags_from_artefact(artefact, doc_hash)
      doc_hash["organisations"] ||= []
      doc_hash["mainstream_browse_pages"] ||= []
      doc_hash["specialist_sectors"] ||= []

      artefact.tags.each do |tag|
        case tag.details.type
        when "organisation"
          doc_hash["organisations"] << tag.slug
        when "section"
          doc_hash["mainstream_browse_pages"] << tag.slug
        when "specialist_sector"
          doc_hash["specialist_sectors"] << tag.slug
        end
      end

      doc_hash["organisations"].uniq!
      doc_hash["mainstream_browse_pages"].uniq!
      doc_hash["specialist_sectors"].uniq!

      # Content API adds two "magic tags" to artefacts when requesting an
      # artefact over the API. Prevent these tags from ending up in Rummager.
      if artefact["owning_app"] == "travel-advice-publisher" && artefact["format"] == "travel-advice"
        doc_hash["mainstream_browse_pages"].delete("abroad/living-abroad")
        doc_hash["mainstream_browse_pages"].delete("abroad/travel-abroad")
      end

      doc_hash
    end
  end
end
