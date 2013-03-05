require "integration_test_helper"
require "app"
require "rest-client"

class ElasticsearchAmendmentTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
    enable_test_index_connections
    create_test_index
    add_sample_document
  end

  def teardown
    clean_index_group
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
    post "/documents", MultiJson.encode(sample_document_attributes)
    assert last_response.ok?
  end

  def test_should_get_a_document_through_elasticsearch
    get "/documents/%2Fan-example-answer"
    assert last_response.ok?
    parsed_response = MultiJson.decode(last_response.body)

    sample_document_attributes.each do |key, value|
      assert_equal value, parsed_response[key]
    end
  end

  def test_should_404_on_missing_document
    get "/documents/%2Fa-missing-answer"
    assert last_response.not_found?
  end

  def test_should_amend_a_document
    post "/documents/%2Fan-example-answer", "title=A+new+title"

    get "/documents/%2Fan-example-answer"
    assert last_response.ok?
    parsed_response = MultiJson.decode(last_response.body)

    updates = {"title" => "A new title"}
    sample_document_attributes.merge(updates).each do |key, value|
      assert_equal value, parsed_response[key]
    end
  end

  def test_should_fail_to_amend_link
    post "/documents/%2Fan-example-answer", "link=/wibble"
    refute last_response.ok?

    get "/documents/%2Fan-example-answer"
    assert last_response.ok?

    get "/documents/%2Fwibble"
    assert last_response.not_found?
  end

  def test_should_404_amending_missing_document
    post "/documents/%2Fa-missing-answer", "title=A+new+title"
    assert last_response.not_found?
  end
end
