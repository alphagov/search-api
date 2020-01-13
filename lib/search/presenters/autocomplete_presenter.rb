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
      es_response["autocomplete"]["hits"].map do |hit|
        hit["_source"]["title"]
      end
    end
  end
end
