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

  def test_should_amend_a_document_queued
    app.settings.enable_queue = true
    commit_document("mainstream_test", {
      "title" => "The old title",
      "link" => "/an-example-answer",
    })

    post "/documents/%2Fan-example-answer", "title=A+new+title"

    assert_equal 202, last_response.status
    assert_document_is_in_rummager({
      "title" => "A new title",
      "link" => "/an-example-answer",
    })
  end

  def test_rejects_unknown_fields
    commit_document("mainstream_test", {
      "title" => "The old title",
      "link" => "/an-example-answer",
    })

    post "/documents/%2Fan-example-answer", "fish=Trout"

    assert 403, last_response.status
    assert_equal "Unrecognised field 'fish'", last_response.body
  end

  def test_returns_not_found_correctly
    post "/documents/%2Fsome-non-existing-document", "title=A+new+title"

    assert 404, last_response.status
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
