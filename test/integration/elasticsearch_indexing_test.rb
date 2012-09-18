require "integration_test_helper"
require "app"
require "rest-client"

class ElasticsearchIndexingTest < IntegrationTest

  def setup
    use_elasticsearch_for_primary_search
    disable_secondary_search
    WebMock.disable_net_connect!(allow: "localhost:9200")
    clear_elasticsearch_index
  end

  def test_should_send_a_document_to_elasticsearch_when_a_json_document_is_posted
    test_data = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT"
    }

    post "/documents", JSON.dump(test_data)
    assert last_response.ok?

    get "/documents/%2Fan-example-answer"
    assert last_response.ok?

    parsed_response = JSON.parse(last_response.body)

    test_data.each do |key, value|
      assert_equal value, parsed_response[key]
    end
  end

end
