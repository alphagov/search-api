require 'spec_helper'

RSpec.describe 'ElasticsearchAmendmentTest' do
  before do
    stub_tagging_lookup
  end

  it "should amend a document" do
    commit_document("mainstream_test", {
      "title" => "The old title",
      "link" => "/an-example-answer",
    })

    post "/mainstream_test/documents/%2Fan-example-answer", "title=A+new+title"

    expect_document_is_in_rummager(
      {
        "title" => "A new title",
        "link" => "/an-example-answer",
      }, type: "edition",
      index: "mainstream_test",
    )
  end

  it "should amend a document from non edition docs" do
    commit_document("mainstream_test", {
      "title" => "The old title",
      "link" => "/an-example-answer",
    }, type: "aaib_report")

    post "/mainstream_test/documents/%2Fan-example-answer", "title=A+new+title"

    expect_document_is_in_rummager(
      {
        "title" => "A new title",
        "link" => "/an-example-answer",
      },
      type: "aaib_report",
      index: "mainstream_test",
    )
  end

  it "should amend a document queued" do
    commit_document("mainstream_test", {
      "title" => "The old title",
      "link" => "/an-example-answer",
    })

    post "/mainstream_test/documents/%2Fan-example-answer", "title=A+new+title"

    expect(last_response.status).to eq(202)
  end
end
