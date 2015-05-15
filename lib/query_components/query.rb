module QueryComponents
  class Query < BaseComponent
    GOVERNMENT_BOOST_FACTOR = 0.4
    SERVICE_MANUAL_BOOST_FACTOR = 0.1

    def payload
      QueryComponents::BestBets.new(params).wrap(query_hash)
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

      core_query = QueryComponents::CoreQuery.new(params).payload
      boosted_query = QueryComponents::Booster.new(params).wrap(core_query)
      QueryComponents::Popularity.new(params).wrap(boosted_query)
    end
  end
end
