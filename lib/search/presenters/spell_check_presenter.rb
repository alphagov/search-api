module Search
  SpellCheckPresenter = Struct.new(:os_response) do
    def present
      return [] unless any_suggestions?

      suggestions.map do |option|
        if highlighted_suggestions?
          { text: option["text"], highlighted: option["highlighted"] }
        else
          option["text"]
        end
      end
    end

  private

    def any_suggestions?
      os_response["suggest"] && os_response["suggest"].any?
    end

    def highlighted_suggestions?
      suggestions.detect { |option| option.key? "highlighted" }
    end

    def suggestions
      os_response["suggest"]["spelling_suggestions"].first["options"]
    end
  end
end
