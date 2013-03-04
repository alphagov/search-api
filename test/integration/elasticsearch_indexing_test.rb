require "integration_test_helper"
require "rest-client"
require "cgi"

class ElasticsearchIndexingTest < IntegrationTest

  def stub_elasticsearch_settings
    app.settings.stubs(:elasticsearch).returns({
      "base_uri" => "http://localhost:9200",
      "index_names" => ["rummager_test"],
      "default_index" => "rummager_test"
    })
  end

  def setup
    stub_elasticsearch_settings
    WebMock.disable_net_connect!(allow: %r{http://localhost:9200/(_aliases|rummager_test.*)})
    @sample_document = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT"
    }

    # Just in case an old test index exists
    begin
      RestClient.delete "http://localhost:9200/rummager_test"
    rescue RestClient::ResourceNotFound
    end
  end

  def search_server
    Elasticsearch::SearchServer.new(
      app.settings.elasticsearch["base_uri"],
      app.settings.elasticsearch_schema,
      app.settings.elasticsearch_schema["index_names"]
    )
  end

  def teardown
    index_group = search_server.index_group("rummager_test")
    index_group.clean
  end

  def create_test_index
    index_group = search_server.index_group("rummager_test")
    index = index_group.create_index
    index_group.switch_to(index)
  end

  def retrieve_document_from_rummager(link)
    get "/documents/#{CGI::escape(link)}"
    MultiJson.decode(last_response.body)
  end

  def assert_document_is_in_rummager(document)
    retrieved = retrieve_document_from_rummager(document['link'])

    assert_equal document.keys.sort, retrieved.keys.sort

    document.each do |key, value|
      assert_equal value, retrieved[key], "Field #{key} should be '#{value}' but was '#{retrieved[key]}'"
    end
  end

  def test_should_indicate_success_in_response_code_when_adding_a_new_document
    create_test_index

    post "/documents", MultiJson.encode(@sample_document)
    assert last_response.ok?
  end

  def test_after_adding_a_document_to_index_should_be_able_to_retrieve_it_again
    create_test_index

    post "/documents", MultiJson.encode(@sample_document)

    assert_document_is_in_rummager(@sample_document)
  end

  def test_should_be_able_to_index_a_document_with_additional_fields
    add_field_to_mappings("topics")
    create_test_index

    test_data = @sample_document.merge("topics" => [1,2])

    post "/documents", MultiJson.encode(test_data)

    assert_document_is_in_rummager(test_data)
  end
end
