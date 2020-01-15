require "aws-sdk-sagemaker"
require "httparty"

module LearnToRank
  class RankerStatus
    include RankerApiHelper

    attr_reader :errors

    def initialize(timeout: 0.1)
      @errors = [] # Strings
      @timeout = timeout
      @healthy = check_health
    end

    def healthy?
      @healthy && errors.none?
    end

  private

    attr_reader :timeout

    GOOD_STATES = %w(AVAILABLE).freeze
    GOOD_STATUSES = %w(OK).freeze

    def check_health
      begin
        reranker_healthy
      rescue StandardError => e
        @errors << "#{e.class}: #{e.message}"
        false
      end
    end

    class RankerServerError < StandardError
      attr_reader :message
      def initialize(message: nil)
        @message = message # String
      end
    end
    class StatusRequestFailed < RankerServerError; end
    class StatusResponseInvalid < RankerServerError; end
    class ModelUndefined < RankerServerError; end
    class ModelStateUnhealthy < RankerServerError; end
    class ModelStatusUnhealthy < RankerServerError; end

    def reranker_healthy
      endpoint = ENV["TENSORFLOW_SAGEMAKER_ENDPOINT"]
      endpoint ? sagemaker_healthy? : container_healthy?
    end

    def sagemaker_healthy?
      # TODO:
      true
    end

    def container_healthy?
      options = {
        headers: { "Content-Type" => "application/json" },
        timeout: timeout, # seconds
      }
      response = HTTParty.get(tensorflow_container_url, options)
      validate_response!(response)
      model = JSON.parse(response.body).fetch("model_version_status", []).last
      validate_model_healthy!(model)
      true
    rescue HTTParty::Error, SocketError, Timeout::Error => e
      raise RankerServerError.new(message: e.message)
    end

    def validate_response!(response)
      return unless response.body.nil? || response.body.empty? || response.code != 200

      raise StatusResponseInvalid.new(message: "Invalid response received from reranker")
    end

    def validate_model_healthy!(model)
      unless model.present?
        raise ModelUndefined.new(message: "No model_version_status model")
      end

      state = model.dig("state")
      unless GOOD_STATES.include?(state)
        raise ModelStateUnhealthy.new(message: "'#{state}' is not a healthy state")
      end

      status = model.dig("status", "error_code")
      unless GOOD_STATUSES.include?(status)
        raise ModelStatusUnhealthy.new(
          message: "Status: '#{status}'. Error: #{model.dig('status', 'error_message')}",
        )
      end
    end
  end
end
