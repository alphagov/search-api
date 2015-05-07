module QueryComponents
  class Suggest
    SPELLING_FIELD = 'spelling_text'

    attr_reader :search_term

    def initialize(search_term)
      @search_term = search_term
    end

    def payload
      {
        text: search_term,
        spelling_suggestions: {
          phrase: {
            field: SPELLING_FIELD,
            size: 1,
            direct_generator: [{
              field: SPELLING_FIELD,
              suggest_mode: 'missing',
              sort: 'score'
            }]
          }
        }
      }
    end
  end
end
