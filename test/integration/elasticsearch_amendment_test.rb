require "integration_test_helper"
require "app"
require "rest-client"

class ElasticsearchAmendmentTest < IntegrationTest

  def setup
    use_elasticsearch_for_primary_search
    disable_secondary_search
    WebMock.disable_net_connect!(allow: "localhost:9200")
    clear_elasticsearch_index
    add_sample_document
  end

  def sample_document_attributes
    {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT"
    }
  end

  def add_sample_document
    post "/documents", JSON.dump(sample_document_attributes)
    assert last_response.ok?
  end

  def test_should_get_a_document_through_elasticsearch
    get "/documents/%2Fan-example-answer"
    assert last_response.ok?
    parsed_response = JSON.parse(last_response.body)

    sample_document_attributes.each do |key, value|
      assert_equal value, parsed_response[key]
    end
  end

  def test_should_404_on_missing_document
    get "/documents/%2Fa-missing-answer"
    assert last_response.not_found?
  end
end
