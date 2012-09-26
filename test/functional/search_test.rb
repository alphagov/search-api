# encoding: utf-8
require "integration_test_helper"

class SearchTest < IntegrationTest
  def setup
    super
    stub_primary_and_secondary_searches
    disable_secondary_search
  end

  def test_autocomplete_cache
    stub_backend
    @backend_index.stubs(:autocomplete_cache).returns([
      sample_document,
      sample_document
    ])
    get "/preload-autocomplete"
    assert last_response.ok?

    results = JSON.parse last_response.body
    assert_equal 2, results.size
  end

  def test_should_return_autocompletion_documents_as_json
    stub_backend
    @backend_index.stubs(:complete).returns([sample_document])
    get "/autocomplete", {q: "bob"}
    assert last_response.ok?
    assert_equal [sample_document_attributes], JSON.parse(last_response.body)
  end

  def test_we_pass_the_optional_filter_parameter_to_autocomplete
    stub_backend
    @backend_index.expects(:complete).with("anything", "my-format").returns([])
    get "/autocomplete", {q: "anything", format_filter: "my-format"}
  end

  def test_returns_json_for_search_results
    @primary_search.stubs(:search).returns([
      sample_document
    ])
    get "/search", {q: "bob"}, "HTTP_ACCEPT" => "application/json"
    assert_equal [sample_document_attributes.merge("highlight"=>"DESCRIPTION")], JSON.parse(last_response.body)
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

  def test_returns_json_when_requested_with_url_suffix
    @primary_search.stubs(:search).returns([
      sample_document
    ])
    get "/search.json", {q: "bob"}
    assert_equal [sample_document_attributes.merge("highlight"=>"DESCRIPTION")], JSON.parse(last_response.body)
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

  def test_should_ignore_edge_spaces_and_codepoints_below_0x20
    @primary_search.expects(:search).never
    get "/search", {q: " \x02 "}
    assert_no_match /we can’t find any results/, last_response.body
  end

  def test_returns_404_for_empty_queries
    @primary_search.expects(:search).never
    get "/search"
    assert last_response.not_found?
  end
end
