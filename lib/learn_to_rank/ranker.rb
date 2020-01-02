require "aws-sdk-sagemakerruntime"
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
      endpoint = ENV["TENSORFLOW_SAGEMAKER_ENDPOINT"]
      if endpoint
        fetch_new_scores_from_sagemaker(examples, endpoint)
      else
        fetch_new_scores_from_serving(examples)
      end
    end

    def fetch_new_scores_from_sagemaker(examples, endpoint)
      begin
        response = Aws::SageMakerRuntime::Client.new.invoke_endpoint(
          endpoint_name: endpoint,
          body: {
            "signature_name": "regression",
            "examples": examples,
          }.to_json,
          content_type: "application/json",
          custom_attributes: "tfs-method=regress",
        )
      rescue Aws::SageMakerRuntime::Errors::ServiceError => e
        logger.debug "SageMaker: #{e.message}"
        log_error e.class.to_s
        return nil
      end

      if response.nil? || response.body.blank?
        logger.debug "SageMaker: No response from ranker!"
        log_error "ranker_error.sagemaker"
        return nil
      else
        logger.debug "SageMaker: #{response.body}"
      end

      JSON.parse(response.body).fetch("results")
    end

    def fetch_new_scores_from_serving(examples)
      url = "http://#{tensorflow_serving_ip}:8501/v1/models/ltr:regress"
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
      rescue StandardError => e
        logger.debug "TF Serving: status_code: 500, message: #{e.message}"
        log_error e.class.to_s
        return nil
      end

      if response.nil? || response.body.blank? || response.code != 200
        logger.debug "TF Serving: status_code: 500, message: No response from ranker!"
        log_error "ranker_error.serving"
        return nil
      else
        logger.debug "TF Serving: status_code: #{response.code}, message: #{response.message}"
      end

      JSON.parse(response.body).fetch("results")
    end

    def tensorflow_serving_ip
      if ENV["TENSORFLOW_SERVING_IP"].present?
        ENV["TENSORFLOW_SERVING_IP"]
      elsif %w(development).include? ENV["RACK_ENV"]
        "reranker"
      else
        "0.0.0.0"
      end
    end

    def log_error(error)
      Services.statsd_client.increment("learn_to_rank.errors.#{error}")
    end

    def logger
      Logging.logger.root
    end
  end
end
