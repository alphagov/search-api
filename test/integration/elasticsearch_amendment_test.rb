require "integration_test_helper"
require "app"

class ElasticsearchAmendmentTest < IntegrationTest
  def setup
    stub_elasticsearch_settings
    create_test_indexes
  end

  def teardown
    clean_test_indexes
  end

  def test_should_amend_a_document
    commit_document("mainstream_test", {
      "title" => "The old title",
      "link" => "/an-example-answer",
    })

    post "/documents/%2Fan-example-answer", "title=A+new+title"

    assert_document_is_in_rummager({
      "title" => "A new title",
      "link" => "/an-example-answer",
    })
  end

  def test_should_fail_to_amend_link
    commit_document("mainstream_test", {
      "title" => "The title",
      "link" => "/an-example-answer",
    })

    post "/documents/%2Fan-example-answer", "link=/wibble"

    assert_document_is_in_rummager({
      "title" => "The title",
      "link" => "/an-example-answer",
    })
  end
end
