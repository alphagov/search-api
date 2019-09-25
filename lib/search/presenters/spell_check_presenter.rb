module Search
  SpellCheckPresenter = Struct.new(:es_response) do
    def present
      return [] unless any_suggestions?
      es_response["suggest"]["spelling_suggestions"].first["options"].map { |option| option["text"] }
    end

  private

    def any_suggestions?
      es_response["suggest"] && es_response["suggest"].any?
    end
  end
end
