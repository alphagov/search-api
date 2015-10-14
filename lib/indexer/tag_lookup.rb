require 'gds_api/content_api'

module Indexer
  class TagLookup
    def prepare_tags(doc_hash)
      artefact = artefact_for_link(doc_hash["link"])
      if artefact.nil?
        return doc_hash
      end

      from_content_api = tags_from_artefact(artefact)
      doc_hash.merge(merge_tags(doc_hash, from_content_api))
    end

  private

    def artefact_for_link(link)
      if link.match(/\Ahttps?:\/\//)
        # We don't support tags for things which are external links.
        return nil
      end
      link = link.sub(/\A\//, '')
      begin
        content_api.artefact!(link)
      rescue GdsApi::HTTPNotFound, GdsApi::HTTPGone
        nil
      end
    end

    def tags_from_artefact(artefact)
      tags = Hash.new { [] }
      artefact.tags.each do |tag|
        slug = tag.slug
        type = tag.details.type
        case type
        when "organisation"
          tags["organisations"] <<= slug
        when "section"
          tags["mainstream_browse_pages"] <<= slug
        when "specialist_sector"
          tags["specialist_sectors"] <<= slug
        end
      end
      tags
    end

    def merge_tags(doc_hash, extra_tags)
      merged_tags = {}
      %w{specialist_sectors mainstream_browse_pages organisations}.each do |tag_type|
        merged_tags[tag_type] = doc_hash.fetch(tag_type, []).concat(extra_tags[tag_type]).uniq
      end
      merged_tags
    end

    def content_api
      @content_api ||= GdsApi::ContentApi.new(Plek.find("contentapi"))
    end
  end
end
