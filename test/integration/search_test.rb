require "test_helper"
require "mocha"
require "document"
require "app"

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

  def test_search_view_with_no_query
    get "/search"
    assert last_response.ok?
    assert last_response.body.include?("You haven't specified a search query")
  end

  def test_search_view_with_query
    SolrWrapper.any_instance.stubs(:search).returns([
      DOCUMENT
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert last_response.body.include?("result for bob")
  end

  def test_search_view_returning_no_results
    SolrWrapper.any_instance.stubs(:search).returns([])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert last_response.body.include?("We can&rsquo;t find any results")
  end

  def test_we_count_result
    SolrWrapper.any_instance.stubs(:search).returns([
      DOCUMENT
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert last_response.body.include?("<strong>1</strong> result ")
  end

  def test_we_count_results
    SolrWrapper.any_instance.stubs(:search).returns([
      DOCUMENT, DOCUMENT
    ])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert last_response.body.include?("<strong>2</strong> results")
  end
end
