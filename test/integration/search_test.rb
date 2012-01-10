# encoding: utf-8
require "test_helper"
require "document"
require "section"
require "app"

class SearchTest < Test::Unit::TestCase
  DOCUMENT_ATTRIBUTES = {
    "title" => "TITLE1",
    "description" => "DESCRIPTION",
    "format" => "local_transaction",
    "section" => "Life in the UK",
    "link" => "/URL"
  }
  RECOMMENDED_DOCUMENT_ATTRIBUTES = {
    "title" => "TITLE1",
    "description" => "DESCRIPTION",
    "format" => "recommended-link",
    "link" => "/URL"
  }
  DOCUMENT = Document.from_hash(DOCUMENT_ATTRIBUTES)
  RECOMMENDED_DOCUMENT = Document.from_hash(RECOMMENDED_DOCUMENT_ATTRIBUTES)

  SECTION = Section.new("bob")

  include Rack::Test::Methods
  include ResponseAssertions

  def app
    Sinatra::Application
  end

  def test_common_search_term_list
    SolrWrapper.any_instance.stubs(:all).returns([
      DOCUMENT,
      DOCUMENT
    ])
    get "/shortcut"
    assert last_response.ok?

    results = JSON.parse last_response.body
    assert_equal 2, results.size
  end

  def test_search_view_with_no_query
    get "/search"
    assert last_response.ok?
    assert_response_text "You haven’t specified a search query"
  end

  def test_search_view_with_query
    SolrWrapper.any_instance.stubs(:search).returns([
      DOCUMENT
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert_response_text "results for “bob”"
  end

  def test_results_is_pluralised_if_multiple_results
    SolrWrapper.any_instance.stubs(:search).returns([
      DOCUMENT,
      DOCUMENT
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert_response_text "results for “bob”"
  end

  def test_recommended_links_appear_if_present
    SolrWrapper.any_instance.stubs(:search).returns([
      RECOMMENDED_DOCUMENT,
      DOCUMENT,
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert last_response.body.include? "search-promoted"
  end

  def test_search_view_returning_no_results
    SolrWrapper.any_instance.stubs(:search).returns([])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert_response_text "We can’t find any results"
  end

  def test_browsing_a_valid_section
    SolrWrapper.any_instance.stubs(:section).returns([
      DOCUMENT
    ])
    get "/browse/bob"
    assert last_response.ok?
  end

  def test_browsing_an_empty_section
    SolrWrapper.any_instance.stubs(:section).returns([])
    get "/browse/bob"
    assert_equal 404, last_response.status
  end

  def test_browsing_an_invalid_section
    SolrWrapper.any_instance.stubs(:search).returns([
      DOCUMENT
    ])
    get "/browse/And%20this"
    assert_equal 404, last_response.status
  end

  def test_browsing_section_list
    SolrWrapper.any_instance.stubs(:facet).returns([
      SECTION
    ])
    get "/browse"
    assert last_response.ok?
  end

  def test_section_list_always_renders
    SolrWrapper.any_instance.stubs(:facet).returns([])
    get "/browse"
    assert last_response.ok?
  end

  def test_we_count_result
    SolrWrapper.any_instance.stubs(:search).returns([
      DOCUMENT
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert_response_text "1 result "
  end

  def test_we_count_results
    SolrWrapper.any_instance.stubs(:search).returns([
      DOCUMENT, DOCUMENT
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert_response_text "2 results"
  end

  def test_should_return_autocompletion_documents_as_json
    SolrWrapper.any_instance.stubs(:complete).returns([DOCUMENT])
    get "/autocomplete", :q => 'bob'
    assert last_response.ok?
    assert_equal [DOCUMENT_ATTRIBUTES], JSON.parse(last_response.body)
  end

  def test_should_send_analytics_headers_for_citizen_proposition
    SolrWrapper.any_instance.stubs(:search).returns([])
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
    SolrWrapper.any_instance.stubs(:search).returns([])
    get "/search", :q => 'bob'
    assert_equal "government", last_response.headers["X-Slimmer-Proposition"]
  end

  def test_should_set_body_class_based_on_proposition_header
    app.settings.stubs(:slimmer_headers).returns(
      section:     "x",
      format:      "y",
      proposition: "blah"
    )
    SolrWrapper.any_instance.stubs(:search).returns([])
    get "/search", :q => 'bob'
    assert_match /<body class="blah"/, last_response.body
  end

  def test_should_respond_with_json_when_requested
    SolrWrapper.any_instance.stubs(:search).returns([
      DOCUMENT
    ])
    get "/search", {:q => "bob"}, "HTTP_ACCEPT" => "application/json"
    assert_equal [DOCUMENT_ATTRIBUTES], JSON.parse(last_response.body)
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

end
