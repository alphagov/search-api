require "uri"
require "net/http"
require "json"
require "cgi"

module HealthCheck
  class JsonSearchClient
    def initialize(options = {})
      @base_url       = options[:base_url] || URI.parse("https://www.gov.uk/api/search.json")
      @authentication = options[:authentication] || nil
      @rate_limit_token = options[:rate_limit_token] || nil
    end

    def search(term, params = {})
      params = { q: term }.merge(params)
      query_string = params.map { |k, v| "#{k}=" + CGI.escape(v.to_s) }.join('&')
      url_components = [@base_url, query_string]

      # base_url can be in the form of example.org/search.json?debug=something
      # or example.org/search.json.
      if @base_url.to_s.include?('?')
        url = url_components.join('&')
      else
        url = url_components.join('?')
      end

      request = Net::HTTP::Get.new(url)
      request.basic_auth(*@authentication) if @authentication
      request["Rate-Limit-Token"] = @rate_limit_token if @rate_limit_token

      response = http_client.request(request)
      case response
      when Net::HTTPSuccess # 2xx
        json_response = JSON.parse(response.body)
        {
          results: extract_results(json_response),
          suggested_queries: json_response['suggested_queries']
        }
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
