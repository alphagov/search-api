module Search
  AutocompletePresenter = Struct.new(:es_response) do
    def present
      return [] unless any_suggestions?

      suggestions
    end

    private

    def any_suggestions?
      es_response["autocomplete"] && es_response["autocomplete"].any?
    end

    def suggestions
      es_response["autocomplete"]
      value = es_response["autocomplete"].map do |result|
        result[1].map do |options|
          options["options"].map do |suggestion|
            suggestion["_source"]["autocomplete"].dig("input")
          end
        end
      end
      value.flatten!
    end
  end
end
