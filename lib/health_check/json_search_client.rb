require "uri"
require "net/http"
require "json"
require "cgi"

module HealthCheck
  class JsonSearchClient
    def initialize(options={})
      @base_url       = options[:base_url] || URI.parse("https://www.gov.uk/api/search.json")
      @authentication = options[:authentication] || nil
    end

    def search(term)
      request = Net::HTTP::Get.new((@base_url + "?q=#{CGI.escape(term)}").request_uri)
      request.basic_auth(*@authentication) if @authentication
      response = http_client.request(request)
      case response
        when Net::HTTPSuccess # 2xx
          json_response = JSON.parse(response.body)
          extract_results(json_response)
        else
          raise "Unexpected response #{response}"
      end
    end

    def to_s
      "JSON endpoint #{@base_url} [auth=#{@authentication ? "yes" : "no"}]"
    end

    private
      def http_client
        @_http_client ||= begin
          http = Net::HTTP.new(@base_url.host, @base_url.port)
          http.use_ssl = (@base_url.scheme == "https")
          http
        end
      end

      def extract_results(json_response)
        if json_response.is_a?(Hash) && json_response.has_key?('results')
          json_response['results'].map { |result| result["link"] }
        else
          raise "Unexpected response format: #{json_response.inspect}"
        end
      end
  end
end
