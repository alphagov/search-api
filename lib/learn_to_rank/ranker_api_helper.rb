module LearnToRank
  module RankerApiHelper
    def which_reranker
      if sagemaker_endpoint
        :sagemaker
      elsif tensorflow_container_url
        :container
      end
    end

    def sagemaker_endpoint(variant: nil)
      envvar = ENV["TENSORFLOW_SAGEMAKER_ENDPOINT"]
      return envvar unless envvar.present? && variant.present?

      "#{envvar}-#{variant}"
    end

    def tensorflow_container_url
      if tensorflow_container_host
        "http://#{tensorflow_container_host}:8501/v1/models/ltr"
      end
    end

    def tensorflow_container_host
      if ENV["TENSORFLOW_SERVING_IP"]
        ENV["TENSORFLOW_SERVING_IP"]
      elsif ENV["RACK_ENV"] == "development"
        "reranker"
      end
    end
  end
end
