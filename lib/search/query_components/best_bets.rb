module QueryComponents
  class BestBets < BaseComponent
    def initialize(metasearch_index:, search_params: Search::QueryParameters.new)
      @metasearch_index = metasearch_index

      super(search_params)
    end

    def wrap(original_query)
      return original_query if search_params.disable_best_bets? || no_bets?

      result = {
        bool: {
          should: [original_query] + best_bet_queries,
        },
      }

      unless worst_bets.empty?
        result[:bool][:must_not] = [{ terms: { link: worst_bets } }]
      end

      result
    end

  private

    attr_reader :metasearch_index

    # `best_bet_queries` make sure documents with the specified IDs are returned
    # by elasticsearch. It also adds a huge weight for these results, to
    # make them on top of the search results page.
    #
    # Bets are in ascending order of position (eg, bet #2 is one from the top)
    def best_bet_queries
      bb_max_position = best_bets.keys.max
      best_bets.map do |position, links|
        {
          function_score: {
            query: {
              terms: { link: links },
            },
            weight: (bb_max_position + 1 - position) * 1_000_000,
          },
        }
      end
    end

    def no_bets?
      best_bets.empty? && worst_bets.empty?
    end

    def best_bets
      @best_bets ||= best_bets_checker.best_bets
    end

    def worst_bets
      @worst_bets ||= best_bets_checker.worst_bets
    end

    def best_bets_checker
      @best_bets_checker ||= Search::BestBetsChecker.new(search_term, metasearch_index)
    end
  end
end
