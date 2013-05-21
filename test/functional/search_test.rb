# encoding: utf-8
require "integration_test_helper"

class SearchTest < IntegrationTest
  def test_returns_json_for_search_results
    stub_index.expects(:search).returns(stub(results: [sample_document]))
    get "/search", {q: "bob"}, "HTTP_ACCEPT" => "application/json"
    assert_equal [sample_document_attributes], MultiJson.decode(last_response.body)
    assert_match(/application\/json/, last_response.headers["Content-Type"])
  end

  def test_returns_json_when_requested_with_url_suffix
    stub_index.expects(:search).returns(stub(results: [sample_document]))
    get "/search.json", {q: "bob"}
    assert_equal [sample_document_attributes], MultiJson.decode(last_response.body)
    assert_match(/application\/json/, last_response.headers["Content-Type"])
  end

  def test_returns_404_when_requested_with_non_json_url
    stub_index.expects(:search).never
    get "/search.xml", {q: "bob"}
    assert last_response.not_found?
  end

  def test_should_ignore_edge_spaces_and_codepoints_below_0x20
    stub_index.expects(:search).never
    get "/search", {q: " \x02 "}
    refute_match(/we can’t find any results/, last_response.body)
  end

  def test_returns_404_for_empty_queries
    stub_index.expects(:search).never
    get "/search"
    assert last_response.not_found?
  end
end
