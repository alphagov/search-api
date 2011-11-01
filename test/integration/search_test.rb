require "test_helper"
require "mocha"

require File.dirname(__FILE__) + "/../../app"

class SearchTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_search_view_renders_successfully
    get "/search"
    assert last_response.ok?
  end

  def test_search_view_with_no_query
    get "/search"
    assert last_response.ok?
    assert last_response.body.include?("You haven't specified a search query")
  end

  def test_search_view_with_query
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert last_response.body.include?("results for bob")
  end

  def test_search_view_returning_no_results
    SearchEngine.any_instance.stubs(:search).returns([])
    get "/search", :q => 'bob'
    assert last_response.ok?
    assert last_response.body.include?("We can&rsquo;t find any results")
  end
end
