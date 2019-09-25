module GovukIndex
  class DetailsPresenter
    extend MethodBuilder

    SERVICE_MANUAL = %w(service_manual_guide service_manual_topic).freeze

    set_payload_method :details

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
          .max_by { |note| DateTime.parse(note["published_at"]) }


        note_info["change_note"] + " in " + note_info["title"]
      end
    end

    def parent_manual
      service_manual || details.dig("manual", "base_path")
    end

    def image_url
      details.dig("image", "url")
    end

  private

    def service_manual
      "/service-manual" if SERVICE_MANUAL.include?(format)
    end

    attr_reader :details, :format
  end
end
