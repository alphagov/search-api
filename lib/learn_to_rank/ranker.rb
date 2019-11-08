require "httparty"

module LearnToRank
  class Ranker
    # Ranker takes feature sets and requests new scores for them
    # from a pre-trained model.
    def initialize(feature_sets = [])
      @feature_sets = feature_sets
    end

    def ranks
      fetch_new_scores(feature_sets).fetch('results', [])
    end

  private

    attr_reader :feature_sets

    def fetch_new_scores(examples)
      url = "http://reranker:8501/v1/models/ltr:regress"
      options = {
        method: "POST",
        body: {
          "signature_name": "regression",
          "examples": examples
        }.to_json,
        headers: { "Content-Type" => "application/json" },
      }
      response = HTTParty.post(url, options)
      JSON.parse(response.body)
    end
  end
end
