require "integration_test_helper"
require "app"

class ElasticsearchAmendmentTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
    create_test_indexes
    add_sample_document
  end

  def teardown
    clean_test_indexes
  end

  def sample_document_attributes
    {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "organisations" => ["hm-magic"],
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT"
    }
  end

  def add_sample_document
    post "/documents", sample_document_attributes.to_json
    assert last_response.ok?
  end

  def test_should_amend_a_document
    post "/documents/%2Fan-example-answer", "title=A+new+title"

    assert_document_is_in_rummager(sample_document_attributes.merge("title" => "A new title"))
  end

  def test_should_fail_to_amend_link
    post "/documents/%2Fan-example-answer", "link=/wibble"

    assert_document_is_in_rummager(sample_document_attributes)
  end
end
