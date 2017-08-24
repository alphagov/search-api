module GovukIndex
  class LicencePresenter
    def initialize(details)
      @details = details
    end

    def identifier
      details['licence_identifier']
    end

    def short_description
      details['licence_short_description']
    end

  private

    attr_reader :details
  end
end
