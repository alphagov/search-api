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
              sort: "score"
            }]
          }
        }
      }
    end
  end
end
