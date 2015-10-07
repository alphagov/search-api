require "integration_test_helper"
require "cgi"

class ElasticsearchIndexingTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
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

  def test_should_indicate_success_in_response_code_when_adding_a_new_document
    create_test_indexes

    post "/documents", @sample_document.to_json

    assert last_response.ok?
    assert_document_is_in_rummager(@sample_document)
  end

  def test_after_adding_a_document_to_index_should_be_able_to_retrieve_it_again_async
    # the queue is disabled in testing by default, but testing/sidekiq/inline
    # executes jobs immediatly.
    app.settings.enable_queue = true
    create_test_indexes

    post "/documents", @sample_document.to_json

    assert_document_is_in_rummager(@sample_document)
  end
end
