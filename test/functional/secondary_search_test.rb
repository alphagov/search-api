# encoding: utf-8
require "integration_test_helper"

class SecondarySearchTest < IntegrationTest

  def setup
    super
    stub_primary_and_secondary_searches
  end

  def test_should_include_secondary_results_in_json_response
    @primary_search.stubs(:search).returns([sample_document])
    sample_specialist_document = sample_document.tap do |document|
      document.link = "/specialist-link"
    end
    @secondary_search.stubs(:search).returns([sample_specialist_document])

    get "/search.json", q: "Not a quote from Back To The Future"
    assert last_response.ok?
    assert_equal(
      [sample_document.link, "/specialist-link"],
      MultiJson.decode(last_response.body).map { |r| r["link"] }
    )
  end
end
