require_relative "../../test_helper"
require "health_check/logging_config"
require "health_check/html_search_client"
Logging.logger.root.appenders = nil

module HealthCheck
  class HtmlSearchClientTest < ShouldaUnitTestCase

    def html_response_body
      query = "things"  # We don't currently care whether the query is displayed

      <<-ENDHTML
  <!DOCTYPE html>
  <html lang="en" class="">
    <head>
      <meta http-equiv="content-type" content="text/html; charset=UTF-8">
      <title>#{query} - Search - GOV.UK</title>
    </head>
    <body>
      <div id="wrapper" class="">
        <section id="content" role="main" class="group search ancillary">
          <div id="search-results-tabs">
            <div class="search-container group js-tab-content tab-content">
              <div id="mainstream-results" class="js-tab-pane tab-pane ">
                <ul class="results-list internal-links">
                  <li class="section-driving type-guide">
                    <p class="search-result-title"><a href="/a">A result</a></p>
                    <p>A summary</p>
                    <ul class="result-meta result-sections">
                      <li class="result-section">Driving</li>
                      <li class="result-subsection">Highway code</li>
                    </ul>
                  </li>
                </ul>
              </div>
              <div id="detailed-results" class="js-tab-pane tab-pane ">
                <ul class="results-list internal-links">
                  <li class="section-driving type-guide">
                    <p class="search-result-title"><a href="/b">A B result</a></p>
                    <p>Another summary</p>
                    <ul class="result-meta result-sections">
                      <li class="result-section">Driving</li>
                      <li class="result-subsection">Highway code</li>
                    </ul>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </section>
      </div>
    </body>
  </html>
      ENDHTML
    end

    def stub_html(search_term, index="mainstream")
      stub_request(:get, "http://www.dev.gov.uk/search?q=#{CGI.escape(search_term)}").
              to_return(
                status: 200,
                headers: {'Content-Type' => 'text/html; charset=utf-8'},
                body: html_response_body
              )
    end

    should "support HTML format" do
      stub_html("bagels")
      expected = ["/a"]
      base_url = URI.parse("http://www.dev.gov.uk/search")
      assert_equal expected, HtmlSearchClient.new(base_url: base_url).search("bagels")
    end

    should "allow overriding the index name" do
      stub_html("chalk")
      expected = ["/b"]
      base_url = URI.parse("http://www.dev.gov.uk/search")
      client = HtmlSearchClient.new(base_url: base_url, index: "detailed")
      assert_equal expected, client.search("chalk")
    end

    context "4xx response" do
      should "raise an error" do
        base_url = URI.parse("https://www.gov.uk/notsearch")
        search_term = "a"
        search_url = (base_url + "?q=#{CGI.escape(search_term)}").to_s
        stub_request(:get, search_url).
              with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
              to_return(status: 404, body: "Newp")

        assert_raises RuntimeError do
          HtmlSearchClient.new(base_url: base_url).search(search_term)
        end
      end
    end
  end
end