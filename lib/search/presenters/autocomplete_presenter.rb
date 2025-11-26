module Search
  AutocompletePresenter = Struct.new(:es_response) do
    def present
      log_es_response

      return [] unless any_suggestions?

      suggestions
    end

  private

    def any_suggestions?
      es_response["autocomplete"] && es_response["autocomplete"].any?
    end

    def suggestions
      value = es_response["autocomplete"].map do |result|
        result[1].map do |options|
          options["options"].map do |suggestion|
            suggestion["_source"]["autocomplete"]["input"]
          end
        end
      end
      value.flatten!
    end

    def log_es_response
      @logger = Logging.logger[self]
      @logger.debug("ES RESPONSE: #{es_response}")
    end
  end
end
