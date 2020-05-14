require "spec_helper"

RSpec.describe "ElasticsearchAmendmentTest" do
  before do
    stub_tagging_lookup
  end

  it "amends a document" do
    commit_document(
      "government_test",
      {
        "title" => "The old title",
        "link" => "/an-example-answer",
      },
    )

    post "/government_test/documents/%2Fan-example-answer", "title=A+new+title"

    expect_document_is_in_rummager(
      {
        "title" => "A new title",
        "link" => "/an-example-answer",
      },
      type: "edition",
      index: "government_test",
    )
  end

  it "amends a document queued" do
    commit_document(
      "government_test",
      {
        "title" => "The old title",
        "link" => "/an-example-answer",
      },
    )

    post "/government_test/documents/%2Fan-example-answer", "title=A+new+title"

    expect(last_response.status).to eq(202)
  end
end
