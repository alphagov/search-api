require 'spec_helper'

RSpec.describe HealthCheck::JsonSearchClient do
  def search_response_body
    {
      "results" => [
        {
          "link" => "/a"
        },
        {
          "link" => "/b"
        }
      ],
      "suggested_queries" => %w(
A
B)
    }
  end

  def stub_search(search_term, custom_headers = {})
    stub_request(:get, "http://www.gov.uk/api/search.json?q=#{CGI.escape(search_term)}").
      with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' }.merge(custom_headers)).
      to_return(status: 200, body: search_response_body.to_json)
  end

  it "support the search format" do
    stub_search("cheese")
    expected = { results: ["/a", "/b"], suggested_queries: %w[A B] }
    base_url = URI.parse("http://www.gov.uk/api/search.json")

    expect(expected).to eq(described_class.new(base_url: base_url).search("cheese"))
  end

  it "call the search API with a rate limit token if provided" do
    stub_search("cheese", "Rate-Limit-Token" => "some_token")

    expected = { results: ["/a", "/b"], suggested_queries: %w[A B] }
    base_url = URI.parse("http://www.gov.uk/api/search.json")

    response = described_class.new(base_url: base_url, rate_limit_token: "some_token").search("cheese")

    expect(expected).to eq(response)
  end
end
