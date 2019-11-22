require "httparty"

module LearnToRank
  class Ranker
    # Ranker takes feature sets and requests new scores for them
    # from a pre-trained model.
    def initialize(feature_sets = [])
      @feature_sets = feature_sets
    end

    def ranks
      return [] unless feature_sets.any?

      GovukStatsd.time("reranker.fetch_scores") do
        fetch_new_scores(feature_sets)
      end
    end

  private

    attr_reader :feature_sets

    def fetch_new_scores(examples)
      url = "http://reranker:8501/v1/models/ltr:regress"
      options = {
        method: "POST",
        body: {
          "signature_name": "regression",
          "examples": examples,
        }.to_json,
        headers: { "Content-Type" => "application/json" },
      }
      response = HTTParty.post(url, options)
      log_response(response)

      return default_ranks(examples) if ranker_error(response)

      JSON.parse(response.body).fetch("results", default_ranks(examples))
    end

    def default_ranks(examples)
      # Use existing rank by giving higher score 3,2,1 to the first results.
      (1..examples.count).reverse_each.to_a
    end

    def ranker_error(response)
      # TODO tell graphite when there's an error
      response.nil? || response.code != 200
    end

    def log_response(response)
      if response
        logger.debug "TF Serving status_code: #{response.code}, message: #{response.message}"
      else
        logger.debug "TF Serving: status_code: 500, message: No response from ranker!"
      end
    end

    def logger
      Logging.logger.root
    end
  end
end
