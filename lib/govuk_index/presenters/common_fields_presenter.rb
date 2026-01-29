module GovukIndex
  class CommonFieldsPresenter
    CUSTOM_FORMAT_MAP = {
      "esi_fund" => "european_structural_investment_fund",
      "external_content" => "recommended-link",
      "field_of_operation" => "operational_field",
      "national_statistics_announcement" => "statistics_announcement",
      "official_statistics_announcement" => "statistics_announcement",
      "service_manual_homepage" => "service_manual_guide",
      "service_manual_service_standard" => "service_manual_guide",
      "working_group" => "policy_group",
    }.freeze

    extend MethodBuilder

    delegate_to_payload :analytics_identifier
    delegate_to_payload :content_id
    delegate_to_payload :content_store_document_type, hash_key: "document_type"
    delegate_to_payload :email_document_supertype
    delegate_to_payload :government_document_supertype
    delegate_to_payload :public_timestamp, hash_key: "public_updated_at"
    delegate_to_payload :publishing_app
    delegate_to_payload :rendering_app
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

    def updated_at
      Time.now
    end

    def base_path
      payload["base_path"]
    end

    def slug
      case format
      when "mainstream_browse_page"
        base_path.gsub(%r{^/browse/}, "")
      when "ministerial_role"
        base_path.gsub(%r{^/government/ministers/}, "")
      when "organisation"
        base_path.gsub(%r{^/government/organisations/}, "").gsub(%r{^/courts-tribunals/}, "")
      when "person"
        base_path.gsub(%r{^/government/people/}, "")
      when "policy"
        base_path.gsub(%r{^/government/policies/}, "")
      end
    end

    def title
      [section_id, payload["title"]].compact.join(" - ")
    end

    def description
      payload["description"]
    end

    def withdrawn?
      !payload["withdrawn_notice"].nil?
    end

    def popularity
      popularity_values[:popularity_score]
    end

    def popularity_b
      popularity_values[:popularity_rank]
    end

    def view_count
      popularity_values[:view_count]
    end

    def format
      document_type = payload["document_type"]
      CUSTOM_FORMAT_MAP[document_type] || document_type
    end

    def section_id
      @_section_id ||= payload.dig("details", "section_id") if format == "hmrc_manual_section"
    end

    def historic?
      political? && government && government.dig("details", "current") == false
    end

    def political?
      payload.dig("details", "political") || false
    end

    def government_name
      government && government["title"]
    end

    def attachments
      (payload.dig("details", "attachments") || []).map do |attachment|
        attachment.slice("content", "title", "isbn", "unique_reference", "command_paper_number", "hoc_paper_number").compact
      end
    end

  private

    attr_reader :payload

    def government
      payload.dig("expanded_links", "government", 0)
    end

    def popularity_values
      @popularity_values ||= begin
        # popularity should be consistent across clusters, so look up in
        # the default
        lookup = Indexer::PopularityLookup.new("govuk_index", SearchConfig.default_instance)
        lookup.lookup_popularities([link])[link] || {}
      end
    end
  end
end
