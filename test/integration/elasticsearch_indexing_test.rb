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
    clean_index_group
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

  def test_indexing_a_promoted_document_sets_the_promoted_for_field
    stub_modified_schema do |schema|
      schema["mappings"]["default"]["edition"]["properties"].merge!(
        "promoted_for" => { "type" => "string", "index" => "analyzed" }
      )

      schema["promoted_results"] = [{
        "link" => "/jobsearch",
        "terms" => "job"
      }]
    end
    create_test_index

    promoted_document = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/jobsearch",
      "indexable_content" => "HERE IS SOME CONTENT"
    }

    post "/documents", MultiJson.encode(promoted_document)

    retrieved_document = retrieve_document_from_rummager(promoted_document['link'])
    assert_equal "job", retrieved_document["promoted_for"]
  end
end
