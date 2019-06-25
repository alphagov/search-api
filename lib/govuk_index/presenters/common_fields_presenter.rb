module GovukIndex
  class CommonFieldsPresenter
    CUSTOM_FORMAT_MAP = {
      "esi_fund" => "european_structural_investment_fund",
      "external_content" => "recommended-link",
      "service_manual_homepage" => "service_manual_guide",
      "service_manual_service_standard" => "service_manual_guide",
      "topic" => "specialist_sector",
    }.freeze
    extend MethodBuilder

    delegate_to_payload :content_id
    delegate_to_payload :content_purpose_document_supertype
    delegate_to_payload :content_store_document_type, hash_key: "document_type"
    delegate_to_payload :description
    delegate_to_payload :email_document_supertype
    delegate_to_payload :government_document_supertype
    delegate_to_payload :navigation_document_supertype
    delegate_to_payload :public_timestamp, hash_key: "public_updated_at"
    delegate_to_payload :publishing_app
    delegate_to_payload :rendering_app
    delegate_to_payload :search_user_need_document_supertype
    delegate_to_payload :user_journey_document_supertype
    delegate_to_payload :content_purpose_supergroup
    delegate_to_payload :content_purpose_subgroup

    def initialize(payload)
      @payload = payload
    end

    def link
      if format == "recommended-link"
        payload["details"]["url"]
      else
        base_path
      end
    end

    def base_path
      payload["base_path"]
    end

    def title
      [section_id, payload["title"]].compact.join(" - ")
    end

    def is_withdrawn
      !payload["withdrawn_notice"].nil?
    end

    def popularity
      # popularity should be consistent across clusters, so look up in
      # the default
      lookup = Indexer::PopularityLookup.new("govuk_index", SearchConfig.instance(Clusters.default_cluster))
      lookup.lookup_popularities([link])[link]
    end

    def format
      document_type = payload['document_type']
      CUSTOM_FORMAT_MAP[document_type] || document_type
    end

    def section_id
      @_section_id ||= payload.dig("details", "section_id") if format == "hmrc_manual_section"
    end

  private

    attr_reader :payload
  end
end
