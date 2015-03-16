require "integration_test_helper"
require "rest-client"
require "cgi"

class ElasticsearchIndexingTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
    enable_test_index_connections
    try_remove_test_index
    @sample_document = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT"
    }
  end

  def teardown
    clean_test_indexes
  end

  def retrieve_document_from_rummager(link)
    get "/documents/#{CGI::escape(link)}"
    JSON.parse(last_response.body)
  end

  def assert_document_is_in_rummager(document)
    retrieved = retrieve_document_from_rummager(document['link'])
    retrieved_document_keys = retrieved.keys - ["popularity"]

    assert_equal document.keys.sort, retrieved_document_keys.sort

    document.each do |key, value|
      assert_equal value, retrieved[key], "Field #{key} should be '#{value}' but was '#{retrieved[key]}'"
    end
  end

  def test_should_indicate_success_in_response_code_when_adding_a_new_document
    create_test_indexes

    post "/documents", @sample_document.to_json
    assert last_response.ok?
  end

  def test_after_adding_a_document_to_index_should_be_able_to_retrieve_it_again
    create_test_indexes

    post "/documents", @sample_document.to_json

    assert_document_is_in_rummager(@sample_document)
  end
end
