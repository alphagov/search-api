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

  private

    attr_reader :details, :format

  end
end
