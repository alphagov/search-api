# encoding: utf-8
require "integration_test_helper"

class AdvancedSearchTest < IntegrationTest
  def setup
    super
    stub_elasticsearch_settings
  end

  def test_returns_json_for_advanced_search_results
    Elasticsearch::Index.any_instance.stubs(:advanced_search)
      .returns(stub(total: 1, results: [sample_document]))

    get "/mainstream_test/advanced_search", {per_page: '1', page: '1', keywords: 'meh'}, "HTTP_ACCEPT" => "application/json"

    assert last_response.ok?, "Bad status: #{last_response.status}"
    assert_match /application\/json/, last_response.headers["Content-Type"]
    assert_equal 1, parsed_response["total"]
  end

  def test_json_response_includes_total_and_results
    Elasticsearch::Index.any_instance.stubs(:advanced_search)
      .returns(stub(total: 1, results: [sample_document]))

    get "/mainstream_test/advanced_search.json", {per_page: '1', page: '1', keywords: 'meh'}

    assert last_response.ok?, "Bad status: #{last_response.status}"
    assert_match /application\/json/, last_response.headers["Content-Type"]
    assert_equal sample_document.title, parsed_response['results'].first['title']
  end
end
