require "integration_test_helper"
require "app"

class ElasticsearchDeletionTest < IntegrationTest
  def setup
    stub_elasticsearch_settings
    create_test_indexes
  end

  def teardown
    clean_test_indexes
  end

  def test_removes_a_document_from_the_index
    commit_document("mainstream_test", {
      "link" => "/an-example-page"
    })

    delete "/documents/%2Fan-example-page"

    assert_document_missing_in_rummager(link: "/an-example-page")
  end

  def test_removes_a_document_from_the_index_queued
    commit_document("mainstream_test", {
      "link" => "/an-example-page"
    })

    delete "/documents/%2Fan-example-page"

    assert_equal 202, last_response.status
  end

  def test_removes_document_with_url
    commit_document("mainstream_test", {
      "link" => "http://example.com/",
    })

    delete "/documents/edition/http:%2F%2Fexample.com%2F"

    assert_document_missing_in_rummager(link: "http://example.com/")
  end

  def test_should_delete_a_best_bet_by_type_and_id
    post "/metasearch_test/documents", {
      "_id" => "jobs_exact",
      "_type" => "best_bet",
      "link" => "/something",
    }.to_json

    commit_index

    delete "/metasearch_test/documents/best_bet/jobs_exact"

    assert_raises RestClient::ResourceNotFound do
      RestClient.get("http://localhost:9200/metasearch_test/best_bet/jobs_exact")
    end
  end

private

  def assert_document_missing_in_rummager(link:)
    assert_raises RestClient::ResourceNotFound do
      fetch_document_from_rummager(link: link)
    end
  end
end
