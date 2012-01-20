# encoding: utf-8
require_relative "integration_helper"

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

  def test_search_view_with_query
    @solr.stubs(:search).returns([
      sample_document,
      sample_document
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    response = Nokogiri.parse(last_response.body)
    assert_equal "Search results for “”", response.css(".site-search h1").inner_text
    assert_equal "bob", response.css(".site-search h1 input").first['value']
  end

  def test_recommended_links_appear_if_present
    @solr.stubs(:search).returns([
      sample_recommended_document,
      sample_document,
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert last_response.body.include? "search-promoted"
  end

  def test_search_view_returning_no_results
    @solr.stubs(:search).returns([])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert_response_text "We can’t find any results"
  end

  def test_we_count_result
    @solr.stubs(:search).returns([
      sample_document
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert_response_text "1 result "
  end

  def test_we_count_results
    @solr.stubs(:search).returns([
      sample_document, sample_document
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert_response_text "2 results"
  end

  def test_should_return_autocompletion_documents_as_json
    @solr.stubs(:complete).returns([sample_document])
    get "/autocomplete", :q => 'bob'
    assert last_response.ok?
    assert_equal [sample_document_attributes], JSON.parse(last_response.body)
  end

  def test_should_send_analytics_headers_for_citizen_proposition
    @solr.stubs(:search).returns([])
    get "/search", :q => 'bob'
    assert_equal "Search",  last_response.headers["X-Slimmer-Section"]
    assert_equal "search",  last_response.headers["X-Slimmer-Format"]
    assert_equal "citizen", last_response.headers["X-Slimmer-Proposition"]
  end

  def test_should_send_analytics_headers_for_government_proposition
    app.settings.stubs(:slimmer_headers).returns(
      section:     "Search",
      format:      "search",
      proposition: "government"
    )
    @solr.stubs(:search).returns([])
    get "/search", :q => 'bob'
    assert_equal "government", last_response.headers["X-Slimmer-Proposition"]
  end

  def test_should_set_body_class_based_on_proposition_header
    app.settings.stubs(:slimmer_headers).returns(
      section:     "x",
      format:      "y",
      proposition: "blah"
    )
    @solr.stubs(:search).returns([])
    get "/search", :q => 'bob'
    assert_match /<body class="blah"/, last_response.body
  end

  def test_should_respond_with_json_when_requested
    @solr.stubs(:search).returns([
      sample_document
    ])
    get "/search", {:q => "bob"}, "HTTP_ACCEPT" => "application/json"
    assert_equal [sample_document_attributes.merge("highlight"=>"DESCRIPTION")], JSON.parse(last_response.body)
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

end
