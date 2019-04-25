module Search
  class BestBetsChecker
    def initialize(query, metasearch_index)
      @query = query
      @fetched = false
      @metasearch_index = metasearch_index
    end

    def best_bets
      fetch
      @best_bets
    end

    def worst_bets
      fetch
      @worst_bets
    end

  private

    # Fetch the best bets, and populate @best_bets and @worst_bets
    def fetch
      return if @fetched
      if @query.nil?
        @best_bets = {}
        @worst_bets = []
      else
        best, worst = select_bets(fetch_bets)
        @best_bets = combine_best_bets(best)
        @worst_bets = combine_worst_bets(worst)
      end
      @fetched = true
    end

    # Combine all the best bets supplied and group them by position.
    #
    # Returns an array of [position, [list of links]] groups.
    #
    # If a link occurs at multiple positions, it will only occur in the group for
    # the highest position it occurred at.
    # Where high means the smallest positional value.
    def combine_best_bets(bets)
      bets
      .map { |bet| [bet['position'], bet['link']] }
      .sort
      .uniq { |_, link| link }
      .each_with_object(Hash.new) do |(position, link), result|
        result[position] ||= []
        result[position] << link
      end
    end

    def combine_worst_bets(bets)
      bets.map { |bet| bet['link'] }.uniq
    end

    # Select the bet entries to use.
    #
    # Returns two arrays, one of best bets and one of worst bets.
    def select_bets(bets)
      exact_bet = bets.find do |bet_type, _best, _worst|
        bet_type == "exact"
      end
      return [exact_bet[1], exact_bet[2]] if exact_bet

      [
        bets.flat_map { |_, best, _| best },
        bets.flat_map { |_, _, worst| worst }
      ]
    end

    # Fetch bet information from elasticsearch
    #
    # Returns an array of 4-tuples, holding:
    #  - query the bet was for
    #  - type of match the bet is for
    #  - the best bets, as an array of hashes
    #  - the worst bets, as an array of hashes
    #
    # The hashes representing bets have a "link" key containing the link for
    # the bet, and for best bets also a "position" key containing the position
    # the best bet should appear at.
    def fetch_bets
      analyzed_users_query = " #{@metasearch_index.analyzed_best_bet_query(@query)} "
      es_response = timed_raw_search(lookup_payload)

      es_response["hits"]["hits"].map do |hit|
        details = JSON.parse(Array(hit["_source"]["details"]).first)
        _bet_query, _, bet_type = hit["_id"].rpartition('-')
        stemmed_query_as_term = Array(hit["_source"]["stemmed_query_as_term"]).first

        # The search on the stemmed_query field is overly broad, so here we need
        # to filter out such matches where the query in the bet is not a
        # substring (modulo stemming) of the user's query.
        if stemmed_query_as_term && !analyzed_users_query.include?(stemmed_query_as_term)
          nil
        else
          [bet_type, details["best_bets"], details["worst_bets"]]
        end
      end
      .compact
    end

    def timed_raw_search(payload)
      GovukStatsd.time("elasticsearch.best_bets_raw_search") do
        @metasearch_index.raw_search(payload)
      end
    end

    # Return a payload for a query across the best_bets type in the metasearch
    # index which will return the best and worst bet entries to use.  Each hit
    # contains a "details" field containing a JSON encoded list of best and worst
    # bets for a query.
    #
    # We limit the number of returned items to 1000: we don't expect to go
    # anywhere near this limit, and performance with 1000 should be okay, but
    # it's a good idea to avoid risking having to deal with huge numbers of
    # returned bets.
    #
    # It's not possible to build an elasticsearch query against the stemmed_query
    # field which only returns results where the entire stemmed_query field value
    # occurs as a phrase in the user's query.  Instead, we do an OR query to
    # obtain a set of candidates which match that field, and use the
    # stemmed_query_as_term field to look for substring matches in the user's query.
    def lookup_payload
      {
        query: {
          bool: {
            should: [
              { match: { exact_query: @query } },
              { match: { stemmed_query: @query } },
            ]
          }
        },
        post_filter: {
          bool: { must: { match: { document_type: "best_bet" } } }
        },
        size: 1000,
        _source: {
          includes: %i[details stemmed_query_as_term],
        },
      }
    end
  end
end
