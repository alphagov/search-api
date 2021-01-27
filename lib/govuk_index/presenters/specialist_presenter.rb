module GovukIndex
  class SpecialistPresenter
    extend MethodBuilder

    set_payload_method :metadata

    delegate_to_payload :aircraft_category
    delegate_to_payload :aircraft_type
    delegate_to_payload :alert_type, convert_to_array: true
    delegate_to_payload :assessment_date
    delegate_to_payload :authors
    delegate_to_payload :business_sizes
    delegate_to_payload :business_stages
    delegate_to_payload :case_state, convert_to_array: true
    delegate_to_payload :case_type, convert_to_array: true
    delegate_to_payload :flood_and_coastal_erosion_category
    delegate_to_payload :certificate_status
    delegate_to_payload :class_category
    delegate_to_payload :closed_date
    delegate_to_payload :closing_date
    delegate_to_payload :commodity_type
    delegate_to_payload :continuation_link
    delegate_to_payload :country
    delegate_to_payload :country_of_origin
    delegate_to_payload :date_application
    delegate_to_payload :date_of_completion
    delegate_to_payload :date_of_start
    delegate_to_payload :date_of_occurrence
    delegate_to_payload :date_registration
    delegate_to_payload :date_registration_eu
    delegate_to_payload :decision_subject
    delegate_to_payload :destination_country, convert_to_array: true
    delegate_to_payload :development_sector
    delegate_to_payload :eligible_entities
    delegate_to_payload :fund_state, convert_to_array: true
    delegate_to_payload :fund_type
    delegate_to_payload :funding_amount
    delegate_to_payload :funding_source
    delegate_to_payload :grant_type, convert_to_array: true
    delegate_to_payload :hidden_indexable_content
    delegate_to_payload :industries
    delegate_to_payload :internal_notes
    delegate_to_payload :issued_date
    delegate_to_payload :laid_date
    delegate_to_payload :land_use
    delegate_to_payload :location, convert_to_array: true
    delegate_to_payload :marine_notice_type
    delegate_to_payload :marine_notice_vessel_type
    delegate_to_payload :marine_notice_topic
    delegate_to_payload :market_sector
    delegate_to_payload :medical_specialism
    delegate_to_payload :opened_date
    delegate_to_payload :outcome_type
    delegate_to_payload :project_code
    delegate_to_payload :project_status
    delegate_to_payload :protection_type
    delegate_to_payload :railway_type
    delegate_to_payload :reason_for_protection
    delegate_to_payload :regions
    delegate_to_payload :register
    delegate_to_payload :registered_name
    delegate_to_payload :registration
    delegate_to_payload :report_type, convert_to_array: true
    delegate_to_payload :research_document_type
    delegate_to_payload :result
    delegate_to_payload :review_status
    delegate_to_payload :service_provider
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
    delegate_to_payload :traditional_term_type
    delegate_to_payload :traditional_term_language
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
    delegate_to_payload :uk_market_conformity_assessment_body_email
    delegate_to_payload :uk_market_conformity_assessment_body_legislative_area, convert_to_array: true
    delegate_to_payload :uk_market_conformity_assessment_body_name
    delegate_to_payload :uk_market_conformity_assessment_body_number
    delegate_to_payload :uk_market_conformity_assessment_body_phone
    delegate_to_payload :uk_market_conformity_assessment_body_registered_office_location
    delegate_to_payload :uk_market_conformity_assessment_body_testing_locations, convert_to_array: true
    delegate_to_payload :uk_market_conformity_assessment_body_type, convert_to_array: true
    delegate_to_payload :uk_market_conformity_assessment_body_website
    delegate_to_payload :value_of_funding
    delegate_to_payload :vessel_type
    delegate_to_payload :will_continue_on
    delegate_to_payload :withdrawn_date

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
