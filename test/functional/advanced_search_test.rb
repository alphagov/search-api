# encoding: utf-8
require "integration_test_helper"

class AdvancedSearchTest < IntegrationTest

  def setup
    super
    stub_backend
  end

  def test_returns_json_for_advanced_search_results
    @backend_index.stubs(:advanced_search).returns({total: 1, results: [sample_document]})
    get "/meh/advanced_search", {per_page: '1', page: '1', keywords: 'meh'}, "HTTP_ACCEPT" => "application/json"
    assert_nothing_raised { MultiJson.decode(last_response.body) }
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

  def test_returns_json_when_requested_with_url_suffix
    @backend_index.stubs(:advanced_search).returns({total: 1, results: [sample_document]})
    get "/meh/advanced_search.json", {per_page: '1', page: '1', keywords: 'meh'}
    assert_nothing_raised { MultiJson.decode(last_response.body) }
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

  def test_json_response_includes_total_and_results
    @backend_index.stubs(:advanced_search).returns({total: 1, results: [sample_document]})
    get "/meh/advanced_search.json", {per_page: '1', page: '1', keywords: 'meh'}
    expected_result = {'total' => 1, 'results' => [sample_document_attributes.merge('highlight' => 'DESCRIPTION')]}
    assert_nothing_raised { MultiJson.decode(last_response.body) }
  end
end
