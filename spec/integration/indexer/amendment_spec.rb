require 'spec_helper'

RSpec.describe 'ElasticsearchAmendmentTest', tags: ['integration'] do
  allow_elasticsearch_connection

  before do
    stub_tagging_lookup
  end

  it "should_amend_a_document" do
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

  it "should_amend_a_document_from_non_edition_docs" do
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

  it "should_amend_a_document_queued" do
    commit_document("mainstream_test", {
      "title" => "The old title",
      "link" => "/an-example-answer",
    })

    post "/documents/%2Fan-example-answer", "title=A+new+title"

    assert_equal 202, last_response.status
  end
end
