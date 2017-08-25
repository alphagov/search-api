module GovukIndex
  class ElasticsearchPresenter
    def initialize(payload:, type:)
      @payload = payload
      @type = type
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
      {
        content_id:                         common_fields.content_id,
        content_store_document_type:        common_fields.content_store_document_type,
        description:                        common_fields.description,
        email_document_supertype:           common_fields.email_document_supertype,
        format:                             common_fields.format,
        government_document_supertype:      common_fields.government_document_supertype,
        is_withdrawn:                       common_fields.is_withdrawn,
        link:                               common_fields.link,
        navigation_document_supertype:      common_fields.navigation_document_supertype,
        popularity:                         common_fields.popularity,
        public_timestamp:                   common_fields.public_timestamp,
        publishing_app:                     common_fields.publishing_app,
        rendering_app:                      common_fields.rendering_app,
        title:                              common_fields.title,
        user_journey_document_supertype:    common_fields.user_journey_document_supertype,
        indexable_content:                  details.indexable_content,
        licence_identifier:                 details.licence_identifier,
        licence_short_description:          details.licence_short_description,
        mainstream_browse_pages:            expanded_links.mainstream_browse_pages,
        mainstream_browse_page_content_ids: expanded_links.mainstream_browse_page_content_ids,
        organisations:                      expanded_links.organisations,
        organisation_content_ids:           expanded_links.organisation_content_ids,
        part_of_taxonomy_tree:              expanded_links.part_of_taxonomy_tree,
        primary_publishing_organisation:    expanded_links.primary_publishing_organisation,
        specialist_sectors:                 expanded_links.specialist_sectors,
        taxons:                             expanded_links.taxons,
        topic_content_ids:                  expanded_links.topic_content_ids,
      }
    end

    def format
      common_fields.format
    end

    def base_path
      @_base_path ||= payload["base_path"]
    end

    def valid!
      return if base_path
      raise(ValidationError, "base_path missing from payload")
    end

  private

    attr_reader :payload, :type

    def common_fields
      @_common_fields ||= CommonFieldsPresenter.new(payload)
    end

    def details
      @_details ||=
        DetailsPresenter.new(
          details: payload["details"],
          format: common_fields.format,
          sanitiser: IndexableContentSanitiser.new
        )
    end

    def expanded_links
      @_expanded_links ||= ExpandedLinksPresenter.new(payload["expanded_links"])
    end
  end
end
