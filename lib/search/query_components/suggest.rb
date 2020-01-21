module QueryComponents
  class Suggest < BaseComponent
    SPELLING_FIELD = "spelling_text".freeze

    def payload
      {
        text: search_term,
        spelling_suggestions: {
          phrase: {
            field: SPELLING_FIELD,
            size: 1,
            max_errors: 3,
            direct_generator: [{
              field: SPELLING_FIELD,
              suggest_mode: "missing",
              string_distance: "levenshtein",
              sort: "score",
            }],
          }.merge(highlight),
        },
      }
    end

  private

    def highlight
      if highlighted_suggestion_requested?
        {
          highlight: {
            pre_tag: "<mark>",
            post_tag: "</mark>",
          },
        }
      else
        {}
      end
    end

    def highlighted_suggestion_requested?
      search_params.suggest.include?("spelling_with_highlighting")
    end
  end
end
