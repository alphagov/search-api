require "integration_test_helper"
require "app"

class ElasticsearchDeletionTest < IntegrationTest

  SAMPLE_DOCUMENT_ATTRIBUTES = [
    {
      "documents" => [
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "answer",
          "link" => "/an-example-answer",
          "indexable_content" => "I like my badger: he is tasty and delicious"
        },
        {
          "title" => "Useful government information",
          "description" => "Government, government, government. Developers.",
          "format" => "answer",
          "link" => "/another-example-answer",
          "mainstream_browse_pages" => "crime/example",
          "indexable_content" => "Tax, benefits, roads and stuff"
        },
        {
          "title" => "Some other site",
          "format" => "answer",
          "link" => "http://example.com/",
        },
        {
          "_type" => "cma_case",
          "link" => "/cma-cases/merger-investigation",
          "title" => "Merger investigation",
          "description" => "An investigation into a merger",
          "indexable_content" => "Merger merger merger",
        },
      ]
    },
    {
      "index" => "metasearch_test",
      "documents" => [
        {
          "_id" => "jobs_exact",
          "_type" => "best_bet",
          "query" => "jobs",
          "link" => "/something",
        }
      ]
    }
  ]

  def setup
    stub_elasticsearch_settings
    create_test_indexes

    add_sample_documents
  end

  def teardown
    clean_test_indexes
  end

  def test_should_404_on_deleted_content
    # an-example-answer is added by the sample documents
    delete "/documents/%2Fan-example-answer"

    assert_document_missing_in_rummager(link: "an-example-answer")
  end

  def test_should_delete_an_item_with_a_full_url
    # an-example-answer is added by the sample documents
    delete "/documents/edition/http:%2F%2Fexample.com%2F"
    assert last_response.ok?

    assert_document_missing_in_rummager(link: "http//example.com/")
  end

  def test_should_accept_a_type_to_delete_a_document_when_queuing_enabled
    app.settings.expects(:enable_queue).returns(true)

    delete "/metasearch_test/documents/cma-cases/merger-investigation", _type: "cma_case"
    assert last_response.successful?
  end

  def test_should_delete_a_best_bet_by_type_and_id
    # jobs_exact best bet is added by add_sample_documents
    delete "/metasearch_test/documents/best_bet/jobs_exact"

    assert_raises RestClient::ResourceNotFound do
      RestClient.get("http://localhost:9200/metasearch_test/best_bet/jobs_exact")
    end
  end

  def test_should_default_type_to_edition_and_id_to_link
    # url is added by add_sample_documents
    delete "/documents/http:%2F%2Fexample.com%2F"

    assert_raises RestClient::ResourceNotFound do
      RestClient.get("http://localhost:9200/mainstream_test/edition/#{CGI.escape("http://example.com/")}")
    end
  end

private

  def assert_document_missing_in_rummager(link:)
    assert_raises RestClient::ResourceNotFound do
      fetch_document_from_rummager(link: link)
    end
  end

  def add_sample_documents
    SAMPLE_DOCUMENT_ATTRIBUTES.each do |index_data|
      path = "/documents"
      path = "/#{index_data['index']}#{path}" if index_data.has_key?('index')

      index_data['documents'].each do |sample_document|
        # TODO: Insert data directly into elasticsearch instead of sending
        # it to rummager.
        post path, sample_document.to_json
      end
    end

    commit_index
  end
end
