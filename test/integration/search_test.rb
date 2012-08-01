# encoding: utf-8
require "integration_test_helper"

class SearchTest < IntegrationTest
  def test_autocomplete_cache
    @solr.stubs(:autocomplete_cache).returns([
      sample_document,
      sample_document
    ])
    get "/preload-autocomplete"
    assert last_response.ok?

    results = JSON.parse last_response.body
    assert_equal 2, results.size
  end

  #removing test for now - need to reinstate once new copy is available
  #def test_search_view_with_no_query
  #  get "/search"
  #  assert last_response.ok?
  #  assert_response_text "You haven’t specified a search query"
  #end

  def test_search_view_returning_no_results
    @solr.stubs(:search).returns([])
    get "/search", {q: "bob"}
    assert last_response.ok?
    assert_response_text "we can’t find any results"
  end

  def test_we_pass_the_optional_filter_parameter_to_searches
    @solr.expects(:search).with("anything", "my-format").returns([])
    get "/search", {q: "anything", format_filter: "my-format"}
  end

  def test_we_count_result
    @solr.stubs(:search).returns([
      sample_document
    ])
    get "/search", {q: "bob"}
    assert last_response.ok?
    assert_response_text "1 result "
  end

  def test_we_count_results
    @solr.stubs(:search).returns([
      sample_document, sample_document
    ])
    get "/search", {q: "bob"}
    assert last_response.ok?
    assert_response_text "2 results"
  end

  def test_should_return_autocompletion_documents_as_json
    @solr.stubs(:complete).returns([sample_document])
    get "/autocomplete", {q: "bob"}
    assert last_response.ok?
    assert_equal [sample_document_attributes], JSON.parse(last_response.body)
  end

  def test_we_pass_the_optional_filter_parameter_to_autocomplete
    @solr.expects(:complete).with("anything", "my-format").returns([])
    get "/autocomplete", {q: "anything", format_filter: "my-format"}
  end

  def test_should_send_analytics_headers_for_citizen_proposition
    @solr.stubs(:search).returns([])
    get "/search", {q: "bob"}
    assert_equal "search",  last_response.headers["X-Slimmer-Section"]
    assert_equal "search",  last_response.headers["X-Slimmer-Format"]
    assert_equal "citizen", last_response.headers["X-Slimmer-Proposition"]
    assert_equal "0", last_response.headers["X-Slimmer-Result-Count"]
  end

  def test_result_count_header_with_results
    @solr.stubs(:search).returns(Array.new(15, sample_document))
    get "/search", {q: "bob"}
    assert_equal "15", last_response.headers["X-Slimmer-Result-Count"]
  end

  def test_should_send_analytics_headers_for_government_proposition
    app.settings.stubs(:slimmer_headers).returns(
      section:     "Search",
      format:      "search",
      proposition: "government"
    )
    @solr.stubs(:search).returns([])
    get "/search", {q: "bob"}
    assert_equal "government", last_response.headers["X-Slimmer-Proposition"]
    # Make sure the result count works for government too
    assert_equal "0", last_response.headers["X-Slimmer-Result-Count"]
  end

  def test_should_set_body_class_based_on_proposition_header
    app.settings.stubs(:slimmer_headers).returns(
      section:     "x",
      format:      "y",
      proposition: "blah"
    )
    @solr.stubs(:search).returns([])
    get "/search", {q: "bob"}
    # the mainstream class is temporarily hardcoded while we switch to using it
    assert_match /<body class="blah mainstream"/, last_response.body
  end

  def test_should_respond_with_json_when_requested
    @solr.stubs(:search).returns([
      sample_document
    ])
    get "/search", {q: "bob"}, "HTTP_ACCEPT" => "application/json"
    assert_equal [sample_document_attributes.merge("highlight"=>"DESCRIPTION")], JSON.parse(last_response.body)
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

  def test_should_respond_with_json_when_requested_with_url_suffix
    @solr.stubs(:search).returns([
      sample_document
    ])
    get "/search.json", {q: "bob"}
    assert_equal [sample_document_attributes.merge("highlight"=>"DESCRIPTION")], JSON.parse(last_response.body)
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

  def test_should_ignore_edge_spaces_and_codepoints_below_0x20
    @solr.expects(:search).never
    get "/search", {q: " \x02 "}
    assert_no_match /we can’t find any results/, last_response.body
  end

  def test_should_not_blow_up_with_a_result_wihout_a_section
    @solr.stubs(:search).returns([
      Document.from_hash({
        "title" => "TITLE1",
        "description" => "DESCRIPTION",
        "format" => "local_transaction",
        "link" => "/URL"
      })
    ])

    assert_nothing_raised do
      get "/search", {q: "bob"}
    end
  end

  def test_should_not_allow_xss_vulnerabilites_as_search_terms
    @solr.stubs(:search).returns([])
    get "/search", {q: "1+\"><script+src%3Dhttp%3A%2F%2F88.151.219.231%2F4><%2Fscript>"}

    assert_response_text "Sorry, we can’t find any results for"
    assert_match "\"1+&quot;&gt;&lt;script+src%3Dhttp%3A%2F%2F88.151.219.231%2F4&gt;&lt;%2Fscript&gt;\"", last_response.body
  end
end
