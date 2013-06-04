require "uri"
require "net/http"
require "nokogiri"
require "cgi"

module HealthCheck
  class HtmlSearchClient
    def initialize(options={})
      @base_url       = options[:base_url] || URI.parse("https://www.gov.uk/search")
      @authentication = options[:authentication] || nil
      @index          = options[:index] || "mainstream"
    end

    def search(term)
      request = Net::HTTP::Get.new((@base_url + "?q=#{CGI.escape(term)}").request_uri)
      request.basic_auth(*@authentication) if @authentication
      response = http_client.request(request)
      case response
        when Net::HTTPSuccess # 2xx
          response_page = Nokogiri::HTML.parse(response.body)
          extract_results(response_page)
        else
          raise "Unexpected response #{response}"
      end
    end

    def to_s
      "HTML endpoint #{@base_url} [index=#{@index} auth=#{@auth.to_s.strip.size>0 ? "yes" : "no"}]"
    end

    private
      def http_client
        @_http_client ||= begin
          http = Net::HTTP.new(@base_url.host, @base_url.port)
          http.use_ssl = (@base_url.scheme == "https")
          http
        end
      end

      def extract_results(response_page)
        response_page.css("##{@index}-results > ul > li").map { |result|
          result.css("a").first.get_attribute("href")
        }
      end
  end
end