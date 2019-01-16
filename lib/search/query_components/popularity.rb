module QueryComponents
  class Popularity < BaseComponent
    POPULARITY_OFFSET = 0.001

    def wrap(boosted_query)
      return boosted_query if search_params.disable_popularity?

      {
        function_score: {
          boost_mode: :multiply, # Multiply script score with query score
          query: boosted_query,
          script_score: {
            script: {
              lang: "painless",
              inline: "doc['popularity'].value + #{POPULARITY_OFFSET}",
            },
          }
        }
      }
    end
  end
end
