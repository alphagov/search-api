require 'spec_helper'

RSpec.describe 'ContentEndpointsTest' do
  it "content_document_not_found" do
    get "/content?link=/a-document/that-does-not-exist"

    expect(last_response).to be_not_found
  end

  it "that_getting_a_document_returns_the_document" do
    commit_document("mainstream_test", {
      "title" => "A nice title",
      "link" => "a-document/in-search",
    })

    get "/content?link=a-document/in-search"

    expect(last_response).to be_ok
    expect("title" => "A nice title", "link" => "a-document/in-search").to eq parsed_response['raw_source']
  end

  it "deleting_a_document" do
    commit_document("mainstream_test", {
      "title" => "A nice title",
      "link" => "a-document/in-search",
    })

    delete "/content?link=a-document/in-search"

    expect(last_response.status).to eq(204)
  end

  it "deleting_a_document_that_doesnt_exist" do
    delete "/content?link=a-document/in-search"

    expect(last_response).to be_not_found
  end

  it "deleting_a_document_from_locked_index" do
    commit_document("mainstream_test", {
      "title" => "A nice title",
      "link" => "a-document/in-search",
    })

    expect_any_instance_of(SearchIndices::Index).to receive(:delete).and_raise(SearchIndices::IndexLocked)

    delete "/content?link=a-document/in-search"

    expect(last_response.status).to eq(423)
  end
end
