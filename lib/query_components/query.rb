require "query_components/core_query"
require "query_components/text_query"

module QueryComponents
  class Query < BaseComponent
    GOVERNMENT_BOOST_FACTOR = 0.4
    SERVICE_MANUAL_BOOST_FACTOR = 0.1

    def payload
      QueryComponents::BestBets.new(search_params).wrap(query_hash)
    end

  private

    def query_hash
      {
        indices: {
          index: :government,
          query: {
            function_score: {
              query: base_query,
              boost_factor: GOVERNMENT_BOOST_FACTOR
            }
          },
          no_match_query: {
            indices: {
              index: :"service-manual",
              query: {
                function_score: {
                  query: base_query,
                  boost_factor: SERVICE_MANUAL_BOOST_FACTOR
                }
              },
              no_match_query: base_query
            }
          }
        }
      }
    end

    def base_query
      if search_term.nil?
        return { match_all: {} }
      end

      if search_params.enable_new_weighting?
        core_query = QueryComponents::TextQuery.new(search_params).payload
      else
        core_query = QueryComponents::CoreQuery.new(search_params).payload
      end
      boosted_query = QueryComponents::Booster.new(search_params).wrap(core_query)
      QueryComponents::Popularity.new(search_params).wrap(boosted_query)
    end
  end
end
