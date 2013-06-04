require_relative "../../test_helper"
require "health_check/logging_config"
require "health_check/json_search_client"
Logging.logger.root.appenders = nil

module HealthCheck
  class JsonSearchClientTest < ShouldaUnitTestCase

    def api_response_body
      {
        "_response_info" => {
          "status" => "ok"
        },
        "results" => [
          {
            "web_url" => "https://www.gov.uk/a"
          },
          {
            "web_url" => "https://www.gov.uk/b"
          },
        ]
      }
    end

    def rummager_response_body
      [
        {
          "link" => "/a"
        },
        {
          "link" => "/b"
        }
      ]
    end

    def stub_api(search_term, index="mainstream")
      stub_request(:get, "https://www.gov.uk/api/search.json?q=#{CGI.escape(search_term)}&index=#{index}").
              with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
              to_return(status: 200, body: api_response_body.to_json)
    end

    def stub_rummager(search_term, index="mainstream")
      stub_request(:get, "http://search.dev.gov.uk/search.json?q=#{CGI.escape(search_term)}&index=#{index}").
              with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
              to_return(status: 200, body: rummager_response_body.to_json)
    end

    should "fetch results" do
      stub_api("carmen")
      expected = ["https://www.gov.uk/a", "https://www.gov.uk/b"]
      assert_equal expected, JsonSearchClient.new.search("carmen")
    end

    should "support Rummager response format" do
      stub_rummager("cheese")
      expected = ["/a", "/b"]
      base_url = URI.parse("http://search.dev.gov.uk/search.json")
      assert_equal expected, JsonSearchClient.new(:base_url => base_url).search("cheese")
    end

    should "allow overriding the index name" do
      stub_api("chalk", "government")
      expected = ["https://www.gov.uk/a", "https://www.gov.uk/b"]
      assert_equal expected, JsonSearchClient.new(index: "government").search("chalk")
    end

    context "4xx response" do
      should "raise an error" do
        index = "doesnotexist"
        search_term = "a"
        stub_request(:get, "https://www.gov.uk/api/search.json?q=#{CGI.escape(search_term)}&index=#{index}").
              with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
              to_return(status: 400, body: "{}")

        assert_raises RuntimeError do
          JsonSearchClient.new(index: index).search(search_term)
        end
      end
    end
  end
end