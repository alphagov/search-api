require "integration_test_helper"
require "app"

class ElasticsearchAmendmentTest < IntegrationTest
  def setup
    super
    stub_tagging_lookup
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

  def test_should_amend_a_document_from_non_edition_docs
    commit_document("mainstream_test", {
      "title" => "The old title",
      "link" => "/an-example-answer",
    }, type: "aaib_report")

    post "/documents/%2Fan-example-answer", "title=A+new+title"

    assert_document_is_in_rummager({
      "title" => "A new title",
      "link" => "/an-example-answer",
    })
  end

  def test_should_preserve_meta_fields
    commit_document("mainstream_test", {
      "title" => "The old title",
      "link" => "/an-example-answer",
    }, type: "aaib_report")

    post "/documents/%2Fan-example-answer", "title=A+new+title"

    retrieved = fetch_raw_document_from_rummager(id: "/an-example-answer")

    assert_equal "aaib_report", retrieved["_type"]
    assert_equal "aaib_report", retrieved["_source"]["_type"]
  end

  def test_should_amend_a_document_queued
    commit_document("mainstream_test", {
      "title" => "The old title",
      "link" => "/an-example-answer",
    })

    post "/documents/%2Fan-example-answer", "title=A+new+title"

    assert_equal 202, last_response.status
  end
end
