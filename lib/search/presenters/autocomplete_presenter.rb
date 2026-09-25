module Search
  AutocompletePresenter = Struct.new(:os_response) do
    def present
      log_os_response

      return [] unless any_suggestions?

      suggestions
    end

  private

    def any_suggestions?
      os_response["autocomplete"] && os_response["autocomplete"].any?
    end

    def suggestions
      value = os_response["autocomplete"].map do |result|
        result[1].map do |options|
          options["options"].map do |suggestion|
            suggestion["_source"]["autocomplete"]["input"]
          end
        end
      end
      value.flatten!
    end

    def log_os_response
      @logger = Logging.logger[self]
      @logger.debug("ES RESPONSE: #{os_response}")
    end
  end
end
