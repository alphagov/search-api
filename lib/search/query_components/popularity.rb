module QueryComponents
  class Popularity < BaseComponent
    POPULARITY_OFFSET = 0.001
    POPULARITY_WEIGHT = 0.0000001

    def wrap(boosted_query)
      return boosted_query if search_params.disable_popularity?

      return logarithmic_boost(boosted_query) if search_params.use_logarithmic_popularity?

      return logarithmic_boost_using_view_count(boosted_query) if search_params.use_view_count_popularity_boost?

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
              inline: "doc['popularity'].value + #{POPULARITY_OFFSET}",
            },
          },
        },
      }
    end

    def logarithmic_boost(boosted_query)
      {
        function_score: {
          boost_mode: :multiply,
          max_boost: 5,
          query: boosted_query,
          field_value_factor: {
            field: "popularity_b",
            modifier: "log1p",
            factor: POPULARITY_WEIGHT,
          },
        },
      }
    end

    def logarithmic_boost_using_view_count(boosted_query)
      {
        function_score: {
          boost_mode: :multiply,
          max_boost: 5,
          query: boosted_query,
          field_value_factor: {
            field: "view_count",
            modifier: "log1p",
            factor: 1,
          },
        },
      }
    end
  end
end
