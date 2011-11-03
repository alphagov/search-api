require "test_helper"
require "mocha"

require "app"

class UpdateTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_should_send_documents_to_solr_when_json_is_posted
    json = JSON.dump(
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT"
    )

    stub_request :post, "http://solr-test-server:9999/solr/rummager/update"

    post "/documents", json

    assert last_response.ok?
    assert_requested :post, "http://solr-test-server:9999/solr/rummager/update",
      body: %r{HERE IS SOME CONTENT}
  end
end
