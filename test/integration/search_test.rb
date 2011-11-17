# encoding: utf-8
require "test_helper"
require "mocha"
require "document"
require "app"
require "htmlentities"

class SearchTest < Test::Unit::TestCase
  DOCUMENT = Document.from_hash(
    "title" => "TITLE1",
    "description" => "DESCRIPTION",
    "format" => "local_transaction",
    "link" => "/URL"
  )

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def assert_response_text(needle)
    haystack = HTMLEntities.new.decode(last_response.body.gsub(/<[^>]+>/, " ").gsub(/\s+/, " "))
    message = "Expected to find #{needle.inspect} in\n#{haystack}"
    assert haystack.include?(needle), message
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
    assert_response_text "result for “bob”"
  end

  def test_search_view_returning_no_results
    SolrWrapper.any_instance.stubs(:search).returns([])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert_response_text "We can’t find any results"
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
    expected = [{
      "title" => "TITLE1",
      "description" => "DESCRIPTION",
      "format" => "local_transaction",
      "link" => "/URL"
    }]
    assert_equal expected, JSON.parse(last_response.body)
  end
end
