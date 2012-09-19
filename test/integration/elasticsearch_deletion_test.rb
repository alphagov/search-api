require "integration_test_helper"
require "app"
require "rest-client"

class ElasticsearchDeletionTest < IntegrationTest

  def setup
    use_elasticsearch_for_primary_search
    disable_secondary_search
    WebMock.disable_net_connect!(allow: "localhost:9200")
    reset_elasticsearch_index
    add_sample_documents
    refresh_index
  end

  def sample_document_attributes
    [
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
      }
    ]
  end

  def add_sample_documents
    sample_document_attributes.each do |sample_document|
      post "/documents", JSON.dump(sample_document)
      assert last_response.ok?
    end
  end

  def refresh_index
    # TODO: replace this with a Rummager request when we have support
    RestClient.post "http://localhost:9200/rummager_test/_refresh", ""
  end

  def assert_no_results
    assert_equal [], JSON.parse(last_response.body)
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

    refresh_index

    get "/search.json?q=cheese"
    assert_no_results
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
