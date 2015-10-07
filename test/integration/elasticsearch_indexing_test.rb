require "integration_test_helper"

class ElasticsearchIndexingTest < IntegrationTest

  SAMPLE_DOCUMENT = {
    "title" => "TITLE",
    "description" => "DESCRIPTION",
    "format" => "answer",
    "link" => "/an-example-answer",
    "indexable_content" => "HERE IS SOME CONTENT"
  }

  def setup
    stub_elasticsearch_settings
    create_test_indexes
  end

  def teardown
    clean_test_indexes
  end

  def test_adding_a_document_to_the_search_index
    post "/documents", SAMPLE_DOCUMENT.to_json

    assert last_response.ok?
    assert_document_is_in_rummager(SAMPLE_DOCUMENT)
  end

  def test_adding_a_document_to_the_search_index_with_queue
    # the queue is disabled in testing by default, but testing/sidekiq/inline
    # executes jobs immediatly.
    app.settings.enable_queue = true

    post "/documents", SAMPLE_DOCUMENT.to_json

    assert_equal 202, last_response.status
    assert_document_is_in_rummager(SAMPLE_DOCUMENT)
  end
end
