module QueryComponents
  class Popularity < BaseComponent
    POPULARITY_OFFSET = 0.001
    POPULARITY_WEIGHT = 0.0000001

    def wrap(boosted_query)
      return boosted_query if search_params.disable_popularity?

      default_popularity_boost(boosted_query)
    end

  private

    def default_popularity_boost(boosted_query)
      {
        function_score: {
          boost_mode: :multiply, # Multiply script score with query score
          query: boosted_query,
          script_score: {
            script: {
              lang: "painless",
              source: "doc['popularity'].value + #{POPULARITY_OFFSET}",
            },
          },
        },
      }
    end
  end
end
