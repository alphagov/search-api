require "set"

class BestBetsChecker
  def initialize(index, query)
    @index = index
    @query = query
    @fetched = false
  end

  def best_bets
    unless @fetched
      fetch
    end
    @best_bets
  end

  def worst_bets
    unless @fetched
      fetch
    end
    @worst_bets
  end

private

  # Fetch the best bets, and populate @best_bets and @worst_bets
  def fetch
    if @query.nil?
      best, worst = [], []
    else
      best, worst = select_bets(fetch_bets)
    end
    @best_bets = combine_best_bets(best)
    @worst_bets = combine_worst_bets(worst)
    @fetched = true
  end

  # Combine all the best bets supplied and group them by position.
  #
  # Returns an array of [position, [list of links]] groups.
  #
  # If a link occurs at multiple positions, it will only occur in the group for
  # the highest position it occurred at.
  def combine_best_bets(bets)
    by_position = bets.map do |bet|
      [bet["position"], bet["link"]]
    end
    by_position.sort!

    combined = Hash.new()
    seen = Set.new
    by_position.each do |bet|
      position, link = bet[0], bet[1]
      if seen.include? link
        next
      end
      seen.add link
      (combined[position] ||= []) << link
    end
    combined
  end

  def combine_worst_bets(bets)
    combined = Set.new
    bets.each do |bet|
      combined.add bet["link"]
    end
    combined.to_a
  end

  # Select the bet entries to use.
  #
  # Returns two arrays, one of best bets and one of worst bets.
  def select_bets(bets)
    exact_bet = bets.find do |bet_query, bet_type, best, worst|
      bet_type == "exact"
    end
    unless exact_bet.nil?
      return [exact_bet[2], exact_bet[3]]
    end

    best_bets = []
    worst_bets = []
    bets.each do |bet_query, bet_type, best, worst|
      best_bets.concat best
      worst_bets.concat worst
    end
    [best_bets, worst_bets]
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
    analyzed_users_query = " #{@index.analyzed_best_bet_query(@query)} "
    es_response = @index.raw_search(lookup_payload, "best_bet")
    result = []
    es_response["hits"]["hits"].map do |hit|
      details = JSON.parse(Array(hit["fields"]["details"]).first)
      bet_query, _, bet_type = hit["_id"].rpartition('-')
      stemmed_query_as_term = Array(hit["fields"]["stemmed_query_as_term"]).first

      # The search on the stemmed_query field is overly broad, so here we need
      # to filter out such matches where the query in the bet is not a
      # substring (modulo stemming) of the user's query.
      unless stemmed_query_as_term.nil?
        unless analyzed_users_query.include? stemmed_query_as_term
          next
        end
      end
      result << [bet_query, bet_type, details["best_bets"], details["worst_bets"]]
    end
    result
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
            { match: { exact_query: @query }},
            { match: { stemmed_query: @query }}
          ]
        }
      },
      size: 1000,
      fields: [ :details, :stemmed_query_as_term ]
    }
  end
end
