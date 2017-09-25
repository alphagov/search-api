require 'spec_helper'

RSpec.describe 'ContentEndpointsTest', tags: ['integration'] do
  it "content_document_not_found" do
    get "/content?link=/a-document/that-does-not-exist"

    assert last_response.not_found?
  end

  it "that_getting_a_document_returns_the_document" do
    commit_document("mainstream_test", {
      "title" => "A nice title",
      "link" => "a-document/in-search",
    })

    get "/content?link=a-document/in-search"

    assert last_response.ok?
    assert_equal(
      { "title" => "A nice title", "link" => "a-document/in-search" },
      parsed_response['raw_source']
    )
  end

  it "deleting_a_document" do
    commit_document("mainstream_test", {
      "title" => "A nice title",
      "link" => "a-document/in-search",
    })

    delete "/content?link=a-document/in-search"

    assert_equal 204, last_response.status
  end

  it "deleting_a_document_that_doesnt_exist" do
    delete "/content?link=a-document/in-search"

    assert last_response.not_found?
  end

  it "deleting_a_document_from_locked_index" do
    commit_document("mainstream_test", {
      "title" => "A nice title",
      "link" => "a-document/in-search",
    })

    SearchIndices::Index.any_instance.expects(:delete).raises(SearchIndices::IndexLocked)

    delete "/content?link=a-document/in-search"

    assert_equal 423, last_response.status
  end
end
