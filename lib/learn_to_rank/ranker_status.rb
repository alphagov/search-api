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

    GOOD_MODEL_STATES = %w[AVAILABLE].freeze
    GOOD_MODEL_STATUSES = %w[OK].freeze
    GOOD_ENDPOINT_STATUSES = %w[InService Updating SystemUpdating].freeze

    def check_health
      reranker_healthy
    rescue StandardError => e
      @errors << "#{e.class}: #{e.message}"
      false
    end

    class RankerServerError < StandardError; end

    class EndpointError < StandardError; end

    class StatusRequestFailed < RankerServerError; end

    class StatusResponseInvalid < RankerServerError; end

    class ModelUndefined < RankerServerError; end

    class ModelStateUnhealthy < RankerServerError; end

    class ModelStatusUnhealthy < RankerServerError; end

    class EndpointApiError < EndpointError; end

    class EndpointStatusUnhealthy < EndpointError; end

    def reranker_healthy
      case which_reranker
      when :sagemaker
        sagemaker_healthy?
      when :container
        container_healthy?
      else
        true
      end
    end

    def sagemaker_healthy?
      response = Aws::SageMaker::Client.new.describe_endpoint(endpoint_name: sagemaker_endpoint)
      validate_endpoint_healthy!(response)
      true
    rescue Aws::SageMaker::Errors::ServiceError => e
      raise EndpointApiError, e.message
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
      raise RankerServerError, e.message
    end

    def validate_response!(response)
      return unless response.body.nil? || response.body.empty? || response.code != 200

      raise StatusResponseInvalid, "Invalid response received from reranker"
    end

    def validate_model_healthy!(model)
      unless model.present?
        raise ModelUndefined, "No model_version_status model"
      end

      state = model["state"]
      unless GOOD_MODEL_STATES.include?(state)
        raise ModelStateUnhealthy, "'#{state}' is not a healthy state"
      end

      status = model.dig("status", "error_code")
      unless GOOD_MODEL_STATUSES.include?(status)
        raise ModelStatusUnhealthy, "Status: '#{status}'. Error: #{model.dig('status', 'error_message')}"
      end
    end

    def validate_endpoint_healthy!(endpoint)
      status = endpoint.endpoint_status
      reason = endpoint.failure_reason

      unless GOOD_ENDPOINT_STATUSES.include?(status)
        if reason.nil? || reason.empty?
          raise EndpointStatusUnhealthy, "Status: '#{status}'."
        else
          raise EndpointStatusUnhealthy, "Status: '#{status}'. Error: #{reason}."
        end
      end
    end
  end
end
