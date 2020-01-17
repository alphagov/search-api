module LearnToRank
  module RankerApiHelper
    def tensorflow_container_url
      "http://#{tensorflow_serving_ip}:8501/v1/models/ltr"
    end

    def tensorflow_serving_ip
      return ENV["TENSORFLOW_SERVING_IP"] if ENV["TENSORFLOW_SERVING_IP"].present?

      return "reranker" if %w(development).include? ENV["RACK_ENV"]

      "0.0.0.0"
    end
  end
end
