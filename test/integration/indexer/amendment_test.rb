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
    }, type: "edition")
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
    }, type: "aaib_report")
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
