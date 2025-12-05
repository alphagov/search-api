module GovukIndex
  class DetailsPresenter
    extend MethodBuilder

    SERVICE_MANUAL = %w[service_manual_guide service_manual_topic].freeze

    set_payload_method :details

    delegate_to_payload :document_type_label
    delegate_to_payload :licence_identifier
    delegate_to_payload :licence_short_description
    delegate_to_payload :url

    def initialize(details:, format:)
      @details = details
      @format = format
    end

    def contact_groups
      details["contact_groups"]&.map { |contact| contact["slug"] }
    end

    def latest_change_note
      return nil if details["change_notes"].nil? || details["change_notes"].empty?

      if format == "hmrc_manual"
        note_info = details["change_notes"]
          .max_by { |note| Time.parse(note["published_at"]) }

        "#{note_info['change_note']} in #{note_info['title']}"
      end
    end

    def parent_manual
      service_manual || details.dig("manual", "base_path")
    end

    def image_url
      details.dig("image", "url")
    end

    def start_date
      details["opening_date"]
    end

    def end_date
      details["closing_date"]
    end

    def has_official_document?
      has_command_paper? || has_act_paper?
    end

    def has_command_paper?
      details["attachments"]&.any? { |attachment| attachment["command_paper_number"].present? || attachment["unnumbered_command_paper"] }
    end

    def has_act_paper?
      details["attachments"]&.any? { |attachment| attachment["hoc_paper_number"].present? || attachment["unnumbered_hoc_paper"] }
    end

    def acronym
      details["acronym"]
    end

    def logo_formatted_title
      details.dig("logo", "formatted_title")
    end

    def logo_url
      details.dig("logo", "image", "url")
    end

    def organisation_brand
      details["brand"]
    end

    def organisation_crest
      details.dig("logo", "crest")
    end

    def organisation_state
      details.dig("organisation_govuk_status", "status")
    end

    def organisation_type
      details["organisation_type"]
    end

  private

    def service_manual
      "/service-manual" if SERVICE_MANUAL.include?(format)
    end

    attr_reader :details, :format
  end
end
