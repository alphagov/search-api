require_relative "../../test_helper"
require "health_check/logging_config"
require "health_check/json_search_client"
Logging.logger.root.appenders = nil

module HealthCheck
  class JsonSearchClientTest < ShouldaUnitTestCase

    def combined_search_response_body
      {
        "streams" => {
          "top-results" => {
            "results" => [
              {
                "link" => "/a"
              }
            ]
          },
          "services-information" => {
            "results" => [
              {
                "link" => "/b"
              },
              {
                "link" => "/c"
              }
            ]
          },
          "departments-policy" => {
            "results" => [
              {
                "link" => "/d"
              }
            ]
          }
        }
      }
    end

    def unified_search_response_body
      {
        "results" => [
          {
            "link" => "/a"
          },
          {
            "link" => "/b"
          }
        ]
      }
    end

    def stub_combined_search(search_term, index="mainstream")
      stub_request(:get, "http://www.gov.uk/api/search/govuk/search.json?q=#{CGI.escape(search_term)}").
              with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
              to_return(status: 200, body: combined_search_response_body.to_json)
    end

    def stub_unified_search(search_term)
      stub_request(:get, "http://www.gov.uk/api/search.json?q=#{CGI.escape(search_term)}").
              with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
              to_return(status: 200, body: unified_search_response_body.to_json)
    end

    should "support combined search response format" do
      stub_combined_search("cheese")
      expected = ["/a", "/b", "/c"]
      base_url = URI.parse("http://www.gov.uk/api/search/govuk/search.json")
      assert_equal expected, JsonSearchClient.new(:base_url => base_url, index: "mainstream").search("cheese")
    end

    should "support combined search response format with an alternative index" do
      stub_combined_search("cheese")
      expected = ["/a", "/d"]
      base_url = URI.parse("http://www.gov.uk/api/search/govuk/search.json")
      assert_equal expected, JsonSearchClient.new(:base_url => base_url, index: "government").search("cheese")
    end

    should "support the unified search format" do
      stub_unified_search("cheese")
      expected = ["/a", "/b"]
      base_url = URI.parse("http://www.gov.uk/api/search.json")
      assert_equal expected, JsonSearchClient.new(:base_url => base_url).search("cheese")
    end
  end
end
