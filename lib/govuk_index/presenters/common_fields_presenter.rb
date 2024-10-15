module GovukIndex
  class CommonFieldsPresenter
    CUSTOM_FORMAT_MAP = {
      "external_content" => "recommended-link",
      "service_manual_homepage" => "service_manual_guide",
      "service_manual_service_standard" => "service_manual_guide",
    }.freeze

    extend MethodBuilder

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
        {
          "content" => attachment["content"],
          "title" => attachment["title"],
          "isbn" => attachment["isbn"],
          "unique_reference" => attachment["unique_reference"],
          "command_paper_number" => attachment["command_paper_number"],
          "hoc_paper_number" => attachment["hoc_paper_number"],
        }.compact
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
