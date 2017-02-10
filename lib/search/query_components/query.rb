require_relative "core_query"
require_relative "text_query"

module QueryComponents
  class Query < BaseComponent
    GOVERNMENT_BOOST_FACTOR = 0.4

    def payload
      if search_params.similar_to.nil?
        QueryComponents::BestBets.new(search_params).wrap(search_query_hash)
      else
        more_like_this_query_hash
      end
    end

  private

    def base_query
      return { match_all: {} } if search_term.nil?

      if search_params.enable_new_weighting?
        core_query = QueryComponents::TextQuery.new(search_params).payload
      else
        core_query = QueryComponents::CoreQuery.new(search_params).payload
      end

      boosted_query = QueryComponents::Booster.new(search_params).wrap(core_query)
      QueryComponents::Popularity.new(search_params).wrap(boosted_query)
    end

    def search_query_hash
      {
        indices: {
          index: :government,
          query: {
            function_score: {
              query: base_query,
              boost_factor: GOVERNMENT_BOOST_FACTOR
            }
          },
          no_match_query: base_query
        }
      }
    end

    def more_like_this_query_hash
      {
        more_like_this: {
          docs: [
            {
              _type: "edition",
              _id: search_params.similar_to
            }
          ]
        }
      }
    end
  end
end
