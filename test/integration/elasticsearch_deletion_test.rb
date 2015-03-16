require "integration_test_helper"
require "app"
require "rest-client"

class ElasticsearchDeletionTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
    enable_test_index_connections
    clean_test_indexes
    create_test_indexes

    add_sample_documents
    commit_index
  end

  def teardown
    clean_test_indexes
  end

  def sample_document_attributes
    [
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
            "section" => "Crime",
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
          }
        ]
      }
    ]
  end

  def add_sample_documents
    sample_document_attributes.each do |index_data|
      path = "/documents"
      path = "/#{index_data['index']}#{path}" if index_data.has_key?('index')

      index_data['documents'].each do |sample_document|
        post path, sample_document.to_json
        assert last_response.ok?
      end
    end
  end

  def commit_index
    post "/commit", nil
  end

  def assert_no_results
    assert_equal [], JSON.parse(last_response.body)["results"]
  end

  def test_should_404_on_deleted_content
    delete "/documents/%2Fan-example-answer"
    assert last_response.ok?

    get "/documents/%2Fan-example-answer"
    assert last_response.not_found?
  end

  def test_should_not_return_deleted_content_in_search
    delete "/documents/%2Fan-example-answer"
    assert last_response.ok?

    commit_index

    get "/search.json?q=cheese"
    assert_no_results
  end

  def test_should_delete_an_item_with_a_full_url
    get "/documents/edition/http:%2F%2Fexample.com%2F"
    assert last_response.ok?

    delete "/documents/edition/http:%2F%2Fexample.com%2F"
    assert last_response.ok?

    get "/documents/edition/http:%2F%2Fexample.com%2F"
    assert last_response.not_found?
  end

  def test_should_accept_a_type_to_delete_a_document
    delete "/metasearch_test/documents/cma-cases/merger-investigation", _type: "cma_case"
    assert last_response.ok?
  end

  def test_should_accept_a_type_to_delete_a_document_when_queuing_enabled
    app.settings.expects(:enable_queue).returns(true)

    delete "/metasearch_test/documents/cma-cases/merger-investigation", _type: "cma_case"
    assert last_response.successful?
  end

  def test_should_delete_a_best_bet_by_type_and_id
    get "/metasearch_test/documents/best_bet/jobs_exact"
    assert last_response.ok?

    delete "/metasearch_test/documents/best_bet/jobs_exact"
    assert last_response.ok?

    get "/metasearch_test/documents/best_bet/jobs_exact"
    assert last_response.not_found?
  end

  def test_should_default_type_to_edition_and_id_to_link
    get "/documents/http:%2F%2Fexample.com%2F"
    assert last_response.ok?

    delete "/documents/http:%2F%2Fexample.com%2F"
    assert last_response.ok?

    get "/documents/http:%2F%2Fexample.com%2F"
    assert last_response.not_found?
  end

  def test_should_delete_all_the_things
    delete "/documents?delete_all=yes"
    assert last_response.ok?

    ["/an-example-answer", "/another-example-answer"].each do |link|
      get "/documents/#{CGI.escape(link)}"
      assert last_response.not_found?
    end

    ["badger", "benefits"].each do |query|
      get "/search.json?q=#{query}"
      assert_no_results
    end
  end
end
