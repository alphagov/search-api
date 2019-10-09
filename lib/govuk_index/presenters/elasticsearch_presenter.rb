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
        aircraft_category:                   specialist.aircraft_category,
        aircraft_type:                       specialist.aircraft_type,
        alert_type:                          specialist.alert_type,
        assessment_date:                     specialist.assessment_date,
        business_sizes:                      specialist.business_sizes,
        business_stages:                     specialist.business_stages,
        case_state:                          specialist.case_state,
        case_type:                           specialist.case_type,
        certificate_status:                  specialist.certificate_status,
        closed_date:                         specialist.closed_date,
        closing_date:                        specialist.closing_date,
        commodity_type:                      specialist.commodity_type,
        contact_groups:                      details.contact_groups,
        content_id:                          common_fields.content_id,
        content_purpose_document_supertype:  common_fields.content_purpose_document_supertype,
        content_purpose_subgroup:            common_fields.content_purpose_subgroup,
        content_purpose_supergroup:          common_fields.content_purpose_supergroup,
        content_store_document_type:         common_fields.content_store_document_type,
        continuation_link:                   specialist.continuation_link,
        country:                             specialist.country,
        date_of_occurrence:                  specialist.date_of_occurrence,
        description:                         common_fields.description,
        destination_country:                 specialist.destination_country,
        development_sector:                  specialist.development_sector,
        dfid_authors:                        specialist.dfid_authors,
        dfid_document_type:                  specialist.dfid_document_type,
        dfid_review_status:                  specialist.dfid_review_status,
        dfid_theme:                          specialist.dfid_theme,
        document_type:                       type,
        eligible_entities:                   specialist.eligible_entities,
        email_document_supertype:            common_fields.email_document_supertype,
        facet_groups:                        expanded_links.facet_groups,
        facet_values:                        expanded_links.facet_values,
        first_published_at:                  specialist.first_published_at,
        format:                              common_fields.format,
        fund_state:                          specialist.fund_state,
        fund_type:                           specialist.fund_type,
        funding_amount:                      specialist.funding_amount,
        funding_source:                      specialist.funding_source,
        government_document_supertype:       common_fields.government_document_supertype,
        grant_type:                          specialist.grant_type,
        hidden_indexable_content:            specialist.hidden_indexable_content,
        hmrc_manual_section_id:              common_fields.section_id,
        image_url:                           image_url,
        indexable_content:                   indexable.indexable_content,
        industries:                          specialist.industries,
        is_withdrawn:                        common_fields.is_withdrawn,
        issued_date:                         specialist.issued_date,
        laid_date:                           specialist.laid_date,
        land_use:                            specialist.land_use,
        latest_change_note:                  details.latest_change_note,
        licence_identifier:                  details.licence_identifier,
        licence_short_description:           details.licence_short_description,
        link:                                common_fields.link,
        location:                            specialist.location,
        mainstream_browse_page_content_ids:  expanded_links.mainstream_browse_page_content_ids,
        mainstream_browse_pages:             expanded_links.mainstream_browse_pages,
        manual:                              details.parent_manual,
        market_sector:                       specialist.market_sector,
        medical_specialism:                  specialist.medical_specialism,
        navigation_document_supertype:       common_fields.navigation_document_supertype,
        opened_date:                         specialist.opened_date,
        organisation_content_ids:            expanded_links.organisation_content_ids,
        organisations:                       expanded_links.organisations,
        outcome_type:                        specialist.outcome_type,
        part_of_taxonomy_tree:               expanded_links.part_of_taxonomy_tree,
        people:                              expanded_links.people,
        policy_groups:                       expanded_links.policy_groups,
        popularity:                          common_fields.popularity,
        popularity_b:                        common_fields.popularity_b,
        primary_publishing_organisation:     expanded_links.primary_publishing_organisation,
        public_timestamp:                    common_fields.public_timestamp,
        updated_at:                          common_fields.updated_at,
        publishing_app:                      common_fields.publishing_app,
        railway_type:                        specialist.railway_type,
        regions:                             specialist.regions,
        registration:                        specialist.registration,
        rendering_app:                       common_fields.rendering_app,
        report_type:                         specialist.report_type,
        result:                              specialist.result,
        search_user_need_document_supertype: common_fields.search_user_need_document_supertype,
        service_provider:                    specialist.service_provider,
        sift_end_date:                       specialist.sift_end_date,
        sifting_status:                      specialist.sifting_status,
        slug:                                slug,
        specialist_sectors:                  expanded_links.specialist_sectors,
        stage:                               specialist.stage,
        subject:                             specialist.subject,
        taxons:                              expanded_links.taxons,
        therapeutic_area:                    specialist.therapeutic_area,
        tiers_or_standalone_items:           specialist.tiers_or_standalone_items,
        title:                               common_fields.title,
        topic_content_ids:                   expanded_links.topic_content_ids,
        topical_events:                      expanded_links.topical_events,
        tribunal_decision_categories:        specialist.tribunal_decision_categories,
        tribunal_decision_category:          specialist.tribunal_decision_category,
        tribunal_decision_country:           specialist.tribunal_decision_country,
        tribunal_decision_decision_date:     specialist.tribunal_decision_decision_date,
        tribunal_decision_judges:            specialist.tribunal_decision_judges,
        tribunal_decision_landmark:          specialist.tribunal_decision_landmark,
        tribunal_decision_reference_number:  specialist.tribunal_decision_reference_number,
        tribunal_decision_sub_categories:    specialist.tribunal_decision_sub_categories,
        tribunal_decision_sub_category:      specialist.tribunal_decision_sub_category,
        types_of_support:                    specialist.types_of_support,
        uk_market_conformity_assessment_body_email:    specialist.uk_market_conformity_assessment_body_email,
        uk_market_conformity_assessment_body_legislative_area: specialist.uk_market_conformity_assessment_body_legislative_area,
        uk_market_conformity_assessment_body_name:     specialist.uk_market_conformity_assessment_body_name,
        uk_market_conformity_assessment_body_number:   specialist.uk_market_conformity_assessment_body_number,
        uk_market_conformity_assessment_body_phone:    specialist.uk_market_conformity_assessment_body_phone,
        uk_market_conformity_assessment_body_registered_office_location: specialist.uk_market_conformity_assessment_body_registered_office_location,
        uk_market_conformity_assessment_body_testing_locations: specialist.uk_market_conformity_assessment_body_testing_locations,
        uk_market_conformity_assessment_body_type:     specialist.uk_market_conformity_assessment_body_type,
        uk_market_conformity_assessment_body_website:  specialist.uk_market_conformity_assessment_body_website,
        user_journey_document_supertype:     common_fields.user_journey_document_supertype,
        value_of_funding:                    specialist.value_of_funding,
        vessel_type:                         specialist.vessel_type,
        view_count:                          common_fields.view_count,
        will_continue_on:                    specialist.will_continue_on,
        withdrawn_date:                      specialist.withdrawn_date,
        world_locations:                     expanded_links.world_locations,
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
      if format == "specialist_sector"
        base_path.gsub(%r{^/topic/}, "")
      elsif format == "mainstream_browse_page"
        base_path.gsub(%r{^/browse/}, "")
      elsif format == "policy"
        base_path.gsub(%r{^/government/policies/}, "")
      end
    end

    def common_fields
      @common_fields ||= CommonFieldsPresenter.new(payload)
    end

    def details
      @details ||= DetailsPresenter.new(details: payload["details"], format: common_fields.format)
    end

    def expanded_links
      @expanded_links ||= ExpandedLinksPresenter.new(payload["expanded_links"])
    end

    def specialist
      @specialist ||= SpecialistPresenter.new(payload)
    end

    def newslike?
      return false if common_fields.content_store_document_type == "fatality_notice"

      common_fields.content_purpose_subgroup == "news" ||
        common_fields.content_purpose_subgroup == "speeches_and_statements"
    end
  end
end
