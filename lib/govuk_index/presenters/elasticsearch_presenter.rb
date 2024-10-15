module GovukIndex
  class ElasticsearchPresenter
    include ElasticsearchIdentity

    def initialize(payload:, type_mapper:)
      @payload = payload
      @inferred_type = type_mapper
    end

    def type
      @type ||= @inferred_type.type
    end

    def document
      {
        attachments: common_fields.attachments,
        contact_groups: details.contact_groups,
        content_id: common_fields.content_id,
        content_purpose_subgroup: common_fields.content_purpose_subgroup,
        content_purpose_supergroup: common_fields.content_purpose_supergroup,
        content_store_document_type: common_fields.content_store_document_type,
        description: common_fields.description,
        document_type: type,
        email_document_supertype: common_fields.email_document_supertype,
        format: common_fields.format,
        government_document_supertype: common_fields.government_document_supertype,
        government_name: common_fields.government_name,
        hmrc_manual_section_id: common_fields.section_id,
        image_url:,
        indexable_content: indexable.indexable_content,
        is_historic: common_fields.historic?,
        is_political: common_fields.political?,
        is_withdrawn: common_fields.withdrawn?,
        latest_change_note: details.latest_change_note,
        licence_identifier: details.licence_identifier,
        licence_short_description: details.licence_short_description,
        link: common_fields.link,
        mainstream_browse_page_content_ids: expanded_links.mainstream_browse_page_content_ids,
        mainstream_browse_pages: expanded_links.mainstream_browse_pages,
        manual: details.parent_manual,
        organisation_content_ids: expanded_links.organisation_content_ids,
        organisations: expanded_links.organisations,
        part_of_taxonomy_tree: expanded_links.part_of_taxonomy_tree,
        parts: parts.presented_parts,
        people: expanded_links.people,
        policy_groups: expanded_links.policy_groups,
        popularity: common_fields.popularity,
        popularity_b: common_fields.popularity_b,
        primary_publishing_organisation: expanded_links.primary_publishing_organisation,
        public_timestamp: common_fields.public_timestamp,
        publishing_app: common_fields.publishing_app,
        rendering_app: common_fields.rendering_app,
        role_appointments: expanded_links.role_appointments,
        roles: expanded_links.roles,
        slug:,
        taxons: expanded_links.taxons,
        title: common_fields.title,
        topical_events: expanded_links.topical_events,
        updated_at: common_fields.updated_at,
        user_journey_document_supertype: common_fields.user_journey_document_supertype,
        view_count: common_fields.view_count,
        world_locations: expanded_links.world_locations,
      }.reject { |_, v| v.nil? }
    end

    def updated_at
      common_fields.updated_at
    end

    def format
      common_fields.format
    end

    def base_path
      common_fields.base_path
    end

    def link
      common_fields.link
    end

    def publishing_app
      common_fields.publishing_app
    end

    def valid!
      if format == "recommended-link"
        details.url || raise(MissingExternalUrl, "url missing from details section")
      else
        base_path || raise(NotIdentifiable, "base_path missing from payload")
      end
    end

    def image_url
      details.image_url || (expanded_links.default_news_image if newslike?)
    end

  private

    attr_reader :payload

    def indexable
      IndexableContentPresenter.new(
        format: common_fields.format,
        details: payload["details"],
        sanitiser: IndexableContentSanitiser.new,
      )
    end

    def slug
      case format
      when "mainstream_browse_page"
        base_path.gsub(%r{^/browse/}, "")
      when "policy"
        base_path.gsub(%r{^/government/policies/}, "")
      when "person"
        base_path.gsub(%r{^/government/people/}, "")
      when "ministerial_role"
        base_path.gsub(%r{^/government/ministers/}, "")
      end
    end

    def common_fields
      @common_fields ||= CommonFieldsPresenter.new(payload)
    end

    def details
      @details ||= DetailsPresenter.new(details: payload["details"], format: common_fields.format)
    end

    def parts
      @parts ||= PartsPresenter.new(parts: payload["details"].fetch("parts", []))
    end

    def expanded_links
      @expanded_links ||= ExpandedLinksPresenter.new(payload["expanded_links"])
    end

    def newslike?
      return false if common_fields.content_store_document_type == "fatality_notice"

      common_fields.content_purpose_subgroup == "news" ||
        common_fields.content_purpose_subgroup == "speeches_and_statements"
    end
  end
end
