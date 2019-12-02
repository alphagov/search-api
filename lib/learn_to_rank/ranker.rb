require "httparty"

module LearnToRank
  class Ranker
    # Ranker takes feature sets and requests new scores for them
    # from a pre-trained model.
    def initialize(feature_sets = [])
      @feature_sets = feature_sets
    end

    def ranks
      return nil unless feature_sets.any?

      GovukStatsd.time("reranker.fetch_scores") do
        fetch_new_scores(feature_sets)
      end
    end

  private

    attr_reader :feature_sets

    def fetch_new_scores(examples)
      url = "http://0.0.0.0:8501/v1/models/ltr:regress"
      options = {
        method: "POST",
        body: {
          "signature_name": "regression",
          "examples": examples,
        }.to_json,
        headers: { "Content-Type" => "application/json" },
      }

      begin
        response = HTTParty.post(url, options)
      rescue SocketError
        return nil
      end

      log_response(response)

      return nil if ranker_error(response)

      JSON.parse(response.body).fetch("results")
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
