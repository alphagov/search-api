require_relative "../../test_helper"
require "health_check/logging_config"
require "health_check/json_search_client"
Logging.logger.root.appenders = nil

module HealthCheck
  class JsonSearchClientTest < ShouldaUnitTestCase
    def unified_search_response_body
      {
        "results" => [
          {
            "link" => "/a"
          },
          {
            "link" => "/b"
          }
        ],
        "suggested_queries" => [
          "A",
          "B"
        ]
      }
    end

    def stub_unified_search(search_term)
      stub_request(:get, "http://www.gov.uk/api/search.json?q=#{CGI.escape(search_term)}").
        with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(status: 200, body: unified_search_response_body.to_json)
    end

    should "support the unified search format" do
      stub_unified_search("cheese")
      expected = { results: ["/a", "/b"], suggested_queries: %w[A B] }
      base_url = URI.parse("http://www.gov.uk/api/search.json")
      assert_equal expected, JsonSearchClient.new(:base_url => base_url).search("cheese")
    end
  end
end
