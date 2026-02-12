require "spec_helper"

module BestBetTestHelpers
  def get_links(path)
    get(path)
    parsed_response["results"].map { |result| result["link"] }
  end

  def add_best_bet(args)
    payload = build_sample_bet_hash(
      query: args[:query],
      type: args[:type],
      best_bets: [args.slice(:link, :position)],
      worst_bets: [],
    )

    post "/metasearch_test/documents", payload.to_json
    commit_index("metasearch_test")
  end

  def add_worst_bet(args)
    payload = build_sample_bet_hash(
      query: args[:query],
      type: args[:type],
      best_bets: [],
      worst_bets: [args.slice(:link, :position)],
    )

    post "/metasearch_test/documents", payload.to_json
    commit_index("metasearch_test")
  end

  def build_sample_bet_hash(query:, type:, best_bets:, worst_bets:)
    {
      "#{type}_query" => query,
      details: JSON.generate(
        {
          best_bets:,
          worst_bets:,
        },
      ),
      _type: "best_bet",
      _id: "#{query}-#{type}",
    }
  end
end
