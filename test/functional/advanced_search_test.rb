# encoding: utf-8
require "integration_test_helper"

class AdvancedSearchTest < IntegrationTest
  BAD_TEST_MESSAGE = "These tests don't test what they claim to (they accept a 404/empty response body)"
  def setup
    super
    stub_backend
  end

  def assert_valid_json(body, message = "Invalid JSON")
    begin
      MultiJson.decode(body)
    rescue MultiJson::LoadError
      flunk message
    end
  end

  def test_returns_json_for_advanced_search_results
    skip BAD_TEST_MESSAGE
    @backend_index.stubs(:advanced_search).returns({total: 1, results: [sample_document]})
    get "/meh/advanced_search", {per_page: '1', page: '1', keywords: 'meh'}, "HTTP_ACCEPT" => "application/json"
    assert_valid_json last_response.body
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

  def test_returns_json_when_requested_with_url_suffix
    skip BAD_TEST_MESSAGE
    @backend_index.stubs(:advanced_search).returns({total: 1, results: [sample_document]})
    get "/meh/advanced_search.json", {per_page: '1', page: '1', keywords: 'meh'}
    assert_valid_json last_response.body
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

  def test_json_response_includes_total_and_results
    skip BAD_TEST_MESSAGE
    @backend_index.stubs(:advanced_search).returns({total: 1, results: [sample_document]})
    get "/meh/advanced_search.json", {per_page: '1', page: '1', keywords: 'meh'}
    expected_result = {'total' => 1, 'results' => [sample_document_attributes.merge('highlight' => 'DESCRIPTION')]}
    assert_valid_json last_response.body
  end
end
