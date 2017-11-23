module GovukIndex
  class DetailsPresenter
    extend MethodBuilder

    set_payload_method :details

    delegate_to_payload :licence_identifier
    delegate_to_payload :licence_short_description

    def initialize(details:, format:)
      @details = details
      @format = format
    end

    def contact_groups
      details['contact_groups']&.map { |contact| contact['slug'] }
    end

    def latest_change_note
      return nil if details["change_notes"].nil? || details["change_notes"].empty?

      if format == "hmrc_manual"
        note_info = details["change_notes"]
          .sort_by { |note| DateTime.parse(note["published_at"]) }
          .last

        note_info["change_note"] + " in " + note_info["title"]
      end
    end

    def parent_manual
      details.dig("manual", "base_path")
    end

  private

    attr_reader :details, :format

  end
end
