require 'services'

module Indexer
  class TagLookup
    def self.prepare_tags(doc_hash)
      new.prepare_tags(doc_hash)
    end

    def prepare_tags(doc_hash)
      # Rummager contains externals links (that have a full URL in the `link`
      # field). These won't have tags associated with them so we can bail out.
      return doc_hash if doc_hash["link"].match(/\Ahttps?:\/\//)

      artefact = find_document_from_content_api(doc_hash["link"])
      return doc_hash unless artefact
      add_tags_from_artefact(artefact, doc_hash)
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

      doc_hash
    end
  end
end
