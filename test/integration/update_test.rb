require "test_helper"
require "mocha"

require "app"

class UpdateTest < Test::Unit::TestCase
  include Rack::Test::Methods

  ENDPOINT = "http://solr-test-server:9999/solr/rummager/update"

  def app
    Sinatra::Application
  end

  def test_should_send_a_document_to_solr_when_a_json_document_is_posted
    json = JSON.dump(
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT"
    )

    stub_request :post, ENDPOINT

    post "/documents", json

    assert last_response.ok?
    assert_requested :post, ENDPOINT, body: %r{HERE IS SOME CONTENT}
  end

  def test_should_send_documents_to_solr_when_a_json_array_of_documents_is_posted
    json = JSON.dump([{
      "title" => "TITLE1",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT"
    }, {
      "title" => "TITLE2",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT"
    }])

    stub_request :post, "http://solr-test-server:9999/solr/rummager/update"

    post "/documents", json

    assert last_response.ok?
    assert_requested :post, ENDPOINT, body: %r{TITLE1}
    assert_requested :post, ENDPOINT, body: %r{TITLE2}
  end
end
