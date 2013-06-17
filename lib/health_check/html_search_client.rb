require "uri"
require "net/http"
require "nokogiri"
require "cgi"
require "logging"

module HealthCheck
  class HtmlSearchClient

    INDEX_TAB_IDS = {
      "mainstream" => "services-information-results",
      "detailed" => "services-information-results",
      "government" => "department-results"
    }

    TOP_RESULTS_ID = "top-results"

    def logger
      Logging.logger[self]
    end

    def initialize(options={})
      @base_url       = options[:base_url] || URI.parse("https://www.gov.uk/search")
      unless @base_url.path.include? "/search"
        logger.warn "Base URL #{@base_url} does not look like a search page"
      end
      @authentication = options[:authentication] || nil
      @index          = options[:index] || "mainstream"
    end

    def search(term, retries = 2)
      request = Net::HTTP::Get.new((@base_url + "?q=#{CGI.escape(term)}").request_uri)
      request.basic_auth(*@authentication) if @authentication
      response = http_client.request(request)
      case response
        when Net::HTTPSuccess # 2xx
          response_page = Nokogiri::HTML.parse(response.body)
          extract_results(response_page)
        when Net::HTTPBadGateway
          if retries > 0
            logger.info "HTTP 502 response: retrying..."
            search(term, retries - 1)
          else
            raise "Too many failures: #{response}"
          end
        else
          raise "Unexpected response #{response}"
      end
    end

    def to_s
      "HTML endpoint #{@base_url} [index=#{@index} auth=#{@authentication ? "yes" : "no"}]"
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
        top_results_selector = "##{TOP_RESULTS_ID} .results-list > li"
        tab_selector = "##{INDEX_TAB_IDS[@index]} .results-list > li"

        # Count top results as being effectively present in all tabs
        all_results = [top_results_selector, tab_selector].map { |selector|
          results = response_page.css(selector)
          logger.debug "Found #{results.count} results for '#{selector}'"
          results
        }.flatten

        all_results.map { |result|
          result.css("a").first.get_attribute("href")
        }
      end
  end
end
