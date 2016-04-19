require "integration_test_helper"
require "gds_api/test_helpers/content_api"

class ElasticsearchIndexingTest < IntegrationTest
  include GdsApi::TestHelpers::ContentApi

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
    content_api_has_an_artefact("an-example-answer", {
      "tags" => [
        tag_for_slug("bar", "specialist_sector"),
      ]
    })

    post "/documents", {
      "content_id" => "6b965b82-2e33-4587-a70c-60204cbb3e29",
      "title" => "TITLE",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
    }.to_json

    assert_document_is_in_rummager({
      "content_id" => "6b965b82-2e33-4587-a70c-60204cbb3e29",
      "title" => "TITLE",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
      "specialist_sectors" => ["bar"]
    })
  end

  def test_adding_a_document_to_the_search_index_with_queue
    stub_tagging_lookup

    post "/documents", SAMPLE_DOCUMENT.to_json

    assert_equal 202, last_response.status
    assert_document_is_in_rummager(SAMPLE_DOCUMENT)
  end
end
