require "test_helper"
require "app"

class SolrUpdateTest < IntegrationTest
  include Rack::Test::Methods

  def setup
    use_solr_for_primary_search
    disable_secondary_search
  end

  ENDPOINT = "http://solr-test-server:9999/solr/rummager/update"
  SUCCESS_RESPONSE = <<-END
    <response>
      <lst name="responseHeader">
        <int name="status">0</int>
        <int name="QTime">9</int>
      </lst>
    </response>
  END

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

    stub_request(:post, ENDPOINT).
      to_return(body: SUCCESS_RESPONSE)

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

    stub_request(:post, "http://solr-test-server:9999/solr/rummager/update").
      to_return(body: SUCCESS_RESPONSE)

    post "/documents", json

    assert last_response.ok?
    assert_requested :post, ENDPOINT, body: %r{TITLE1}
    assert_requested :post, ENDPOINT, body: %r{TITLE2}
  end

  def test_should_post_delete_by_query_to_solr
    stub_request(:post, "http://solr-test-server:9999/solr/rummager/update").
      to_return(body: SUCCESS_RESPONSE)

    delete "/documents/http%3A%2F%2Fexample.com%2Flink-name"

    assert last_response.ok?
    assert_requested :post, ENDPOINT,
      body: Regexp.new(Regexp.escape("link:http\\://example.com/link\\-name"))
  end

  def test_should_post_delete_using_link_parameter_by_query_to_solr
    stub_request(:post, "http://solr-test-server:9999/solr/rummager/update").
      to_return(body: SUCCESS_RESPONSE)

    delete "/documents", "link=http%3A%2F%2Fexample.com%2Flink-name"

    assert last_response.ok?
    assert_requested :post, ENDPOINT,
      body: Regexp.new(Regexp.escape("link:http\\://example.com/link\\-name"))
  end

  def test_should_post_delete_all_to_solr
    stub_request(:post, "http://solr-test-server:9999/solr/rummager/update").
      to_return(body: SUCCESS_RESPONSE)

    delete "/documents", "delete_all=true"

    assert last_response.ok?
    assert_requested :post, ENDPOINT,
      body: Regexp.new(Regexp.escape("link:[* TO *]"))
  end
end
