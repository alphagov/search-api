module GovukIndex
  class SpecialistPresenter
    extend MethodBuilder

    set_payload_method :metadata

    delegate_to_payload :ai_assurance_technique, convert_to_array: true
    delegate_to_payload :aircraft_category
    delegate_to_payload :aircraft_type
    delegate_to_payload :alert_type, convert_to_array: true
    delegate_to_payload :algorithmic_transparency_record_atrs_version
    delegate_to_payload :algorithmic_transparency_record_capability, convert_to_array: true
    delegate_to_payload :algorithmic_transparency_record_date_published
    delegate_to_payload :algorithmic_transparency_record_function, convert_to_array: true
    delegate_to_payload :algorithmic_transparency_record_organisation
    delegate_to_payload :algorithmic_transparency_record_organisation_type, convert_to_array: true
    delegate_to_payload :algorithmic_transparency_record_other_tags
    delegate_to_payload :algorithmic_transparency_record_phase
    delegate_to_payload :algorithmic_transparency_record_region, convert_to_array: true
    delegate_to_payload :algorithmic_transparency_record_task
    delegate_to_payload :areas_of_interest
    delegate_to_payload :assessment_date
    delegate_to_payload :assurance_technique_approach, convert_to_array: true
    delegate_to_payload :authors
    delegate_to_payload :business_sizes
    delegate_to_payload :business_stages
    delegate_to_payload :category, convert_to_array: true
    delegate_to_payload :case_state, convert_to_array: true
    delegate_to_payload :case_type, convert_to_array: true
    delegate_to_payload :certificate_status
    delegate_to_payload :class_category
    delegate_to_payload :closed_date
    delegate_to_payload :closing_date
    delegate_to_payload :commodity_type
    delegate_to_payload :continuation_link
    delegate_to_payload :country
    delegate_to_payload :country_of_origin
    delegate_to_payload :data_ethics_guidance_document_ethical_theme
    delegate_to_payload :data_ethics_guidance_document_organisation_alias
    delegate_to_payload :data_ethics_guidance_document_project_phase
    delegate_to_payload :data_ethics_guidance_document_technology_area
    delegate_to_payload :date_application
    delegate_to_payload :date_of_completion
    delegate_to_payload :date_of_occurrence
    delegate_to_payload :date_of_start
    delegate_to_payload :date_registration
    delegate_to_payload :date_registration_eu
    delegate_to_payload :decision_subject
    delegate_to_payload :destination_country, convert_to_array: true
    delegate_to_payload :development_sector
    delegate_to_payload :digital_market_research_area, convert_to_array: true
    delegate_to_payload :digital_market_research_category
    delegate_to_payload :digital_market_research_publish_date
    delegate_to_payload :digital_market_research_publisher, convert_to_array: true
    delegate_to_payload :digital_market_research_topic, convert_to_array: true
    delegate_to_payload :disease_case_closed_date
    delegate_to_payload :disease_case_opened_date
    delegate_to_payload :disease_type, convert_to_array: true
    delegate_to_payload :eligible_entities
    delegate_to_payload :flood_and_coastal_erosion_category
    delegate_to_payload :fund_state, convert_to_array: true
    delegate_to_payload :fund_type
    delegate_to_payload :funding_amount
    delegate_to_payload :funding_source
    delegate_to_payload :grant_type, convert_to_array: true
    delegate_to_payload :hidden_indexable_content
    delegate_to_payload :industries
    delegate_to_payload :internal_notes
    delegate_to_payload :trademark_decision_appointed_person_hearing_officer
    delegate_to_payload :trademark_decision_british_library_number
    delegate_to_payload :trademark_decision_class
    delegate_to_payload :trademark_decision_date
    delegate_to_payload :trademark_decision_mark
    delegate_to_payload :trademark_decision_person_or_company_involved
    delegate_to_payload :trademark_decision_grounds_section
    delegate_to_payload :trademark_decision_grounds_sub_section
    delegate_to_payload :trademark_decision_type_of_hearing
    delegate_to_payload :issued_date
    delegate_to_payload :key_function, convert_to_array: true
    delegate_to_payload :keyword
    delegate_to_payload :laid_date
    delegate_to_payload :land_types
    delegate_to_payload :land_use
    delegate_to_payload :licence_transaction_continuation_link
    delegate_to_payload :licence_transaction_industry, convert_to_array: true
    delegate_to_payload :licence_transaction_licence_identifier
    delegate_to_payload :licence_transaction_location, convert_to_array: true
    delegate_to_payload :licence_transaction_will_continue_on
    delegate_to_payload :life_saving_maritime_appliance_service_station_regions, convert_to_array: true
    delegate_to_payload :life_saving_maritime_appliance_type, convert_to_array: true
    delegate_to_payload :life_saving_maritime_appliance_manufacturer, convert_to_array: true
    delegate_to_payload :location, convert_to_array: true
    delegate_to_payload :marine_notice_topic
    delegate_to_payload :marine_notice_type
    delegate_to_payload :marine_notice_vessel_type
    delegate_to_payload :market_sector
    delegate_to_payload :medical_specialism
    delegate_to_payload :opened_date
    delegate_to_payload :outcome_type
    delegate_to_payload :payment_types
    delegate_to_payload :principle, convert_to_array: true
    delegate_to_payload :product_alert_type
    delegate_to_payload :product_category
    delegate_to_payload :product_measure_type
    delegate_to_payload :product_recall_alert_date
    delegate_to_payload :product_risk_level
    delegate_to_payload :project_code
    delegate_to_payload :project_status
    delegate_to_payload :protection_type
    delegate_to_payload :railway_type
    delegate_to_payload :reason_for_protection
    delegate_to_payload :reference_number
    delegate_to_payload :regions
    delegate_to_payload :register
    delegate_to_payload :registered_name
    delegate_to_payload :registration
    delegate_to_payload :report_type, convert_to_array: true
    delegate_to_payload :research_document_type
    delegate_to_payload :result
    delegate_to_payload :review_status
    delegate_to_payload :sector, convert_to_array: true
    delegate_to_payload :service_provider
    delegate_to_payload :sfo_case_date_announced
    delegate_to_payload :sfo_case_state
    delegate_to_payload :sift_end_date
    delegate_to_payload :sifting_status
    delegate_to_payload :stage
    delegate_to_payload :status
    delegate_to_payload :subject
    delegate_to_payload :theme
    delegate_to_payload :therapeutic_area
    delegate_to_payload :tiers_or_standalone_items
    delegate_to_payload :time_registration
    delegate_to_payload :topics
    delegate_to_payload :traditional_term_grapevine_product_category
    delegate_to_payload :traditional_term_language
    delegate_to_payload :traditional_term_type
    delegate_to_payload :tribunal_decision_categories
    delegate_to_payload :tribunal_decision_category
    delegate_to_payload :tribunal_decision_country
    delegate_to_payload :tribunal_decision_decision_date
    delegate_to_payload :tribunal_decision_judges
    delegate_to_payload :tribunal_decision_landmark
    delegate_to_payload :tribunal_decision_reference_number
    delegate_to_payload :tribunal_decision_sub_categories
    delegate_to_payload :tribunal_decision_sub_category
    delegate_to_payload :types_of_support
    delegate_to_payload :use_case, convert_to_array: true
    delegate_to_payload :value_of_funding
    delegate_to_payload :vessel_type
    delegate_to_payload :veterans_support_organisation_health_and_social_care
    delegate_to_payload :veterans_support_organisation_finance
    delegate_to_payload :veterans_support_organisation_legal_and_justice
    delegate_to_payload :veterans_support_organisation_employment_education_and_training
    delegate_to_payload :veterans_support_organisation_housing
    delegate_to_payload :veterans_support_organisation_families_and_children
    delegate_to_payload :veterans_support_organisation_community_and_social
    delegate_to_payload :veterans_support_organisation_region_england
    delegate_to_payload :veterans_support_organisation_region_northern_ireland
    delegate_to_payload :veterans_support_organisation_region_scotland
    delegate_to_payload :veterans_support_organisation_region_wales
    delegate_to_payload :virus_strain
    delegate_to_payload :will_continue_on
    delegate_to_payload :withdrawn_date
    delegate_to_payload :year_adopted
    delegate_to_payload :zone_restriction
    delegate_to_payload :zone_type, convert_to_array: true

    def initialize(payload)
      @payload = payload
      @metadata = @payload.dig("details", "metadata") || {}
    end

    def first_published_at
      metadata["first_published_at"] || @payload["first_published_at"]
    end

  private

    attr_reader :metadata
  end
end
