require "test_helper"

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
end
