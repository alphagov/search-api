require "spec_helper"

RSpec.describe "ContentEndpointsTest" do
  it "content document not found" do
    get "/content?link=/a-document/that-does-not-exist"

    expect(last_response).to be_not_found
  end
  it "that_getting_a_document_returns_the_document" do
    commit_document(
      "govuk_test",
      {
        "title" => "A nice title",
        "link" => "a-document/in-search",
      },
    )

    get "/content?link=a-document/in-search"

    expect(last_response).to be_ok
    expect("title" => "A nice title", "link" => "a-document/in-search", "document_type" => "edition").to eq parsed_response["raw_source"]
  end

  it "deleting a document" do
    commit_document(
      "govuk_test",
      {
        "title" => "A nice title",
        "link" => "a-document/in-search",
      },
    )

    delete "/content?link=a-document/in-search"

    expect(last_response.status).to eq(204)
  end

  it "deleting a document that doesnt exist" do
    delete "/content?link=a-document/in-search"

    expect(last_response).to be_not_found
  end

  it "deleting a document from locked index" do
    commit_document(
      "govuk_test",
      {
        "title" => "A nice title",
        "link" => "a-document/in-search",
      },
    )

    expect_any_instance_of(SearchIndices::Index).to receive(:delete).and_raise(SearchIndices::IndexLocked)

    delete "/content?link=a-document/in-search"

    expect(last_response.status).to eq(423)
  end
end
