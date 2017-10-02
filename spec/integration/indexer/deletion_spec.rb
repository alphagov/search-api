require 'spec_helper'

RSpec.describe 'ElasticsearchDeletionTest', tags: ['integration'] do
  it "removes_a_document_from_the_index" do
    commit_document("mainstream_test", {
      "link" => "/an-example-page"
    })

    delete "/documents/%2Fan-example-page"

    expect_document_missing_in_rummager(id: "/an-example-page")
  end

  it "removes_a_document_from_the_index_queued" do
    commit_document("mainstream_test", {
      "link" => "/an-example-page"
    })

    delete "/documents/%2Fan-example-page"

    expect(last_response.status).to eq(202)
  end

  it "removes_document_with_url" do
    commit_document("mainstream_test", {
      "link" => "http://example.com/",
    })

    delete "/documents/edition/http:%2F%2Fexample.com%2F"

    expect_document_missing_in_rummager(id: "http://example.com/")
  end

  it "should_delete_a_best_bet_by_type_and_id" do
    post "/metasearch_test/documents", {
      "_id" => "jobs_exact",
      "_type" => "best_bet",
      "link" => "/something",
    }.to_json

    commit_index

    delete "/metasearch_test/documents/best_bet/jobs_exact"

    expect {
      client.get(
        index: 'metasearch_test',
        type: 'best_bet',
        id: 'jobs_exact'
      )
    }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
  end

private

  def expect_document_missing_in_rummager(id:)
    expect {
      fetch_document_from_rummager(id: id)
    }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
  end
end
