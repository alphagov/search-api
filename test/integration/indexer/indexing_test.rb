require "integration_test_helper"

class ElasticsearchIndexingTest < IntegrationTest
  include GdsApi::TestHelpers::PublishingApiV2

  SAMPLE_DOCUMENT = {
    "title" => "TITLE",
    "description" => "DESCRIPTION",
    "format" => "answer",
    "link" => "/an-example-answer",
    "indexable_content" => "HERE IS SOME CONTENT"
  }.freeze

  def setup
    stub_elasticsearch_settings
    create_test_indexes
  end

  def teardown
    clean_test_indexes
  end

  def test_adding_a_document_to_the_search_index
    stub_tagging_lookup
    publishing_api_has_expanded_links(
      content_id: "6b965b82-2e33-4587-a70c-60204cbb3e29",
      expanded_links: {},
    )

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
    })
  end

  def test_tagging_organisations_to_self
    stub_tagging_lookup

    post "/documents", {
      "title" => "TITLE",
      "format" => "organisation",
      "slug" => "my-organisation",
      "link" => "/an-example-organisation",
    }.to_json

    assert_document_is_in_rummager({
      "title" => "TITLE",
      "format" => "organisation",
      "slug" => "my-organisation",
      "link" => "/an-example-organisation",
      "organisations" => ["my-organisation"],
    })
  end

  def test_adding_a_document_to_the_search_index_with_organisation_self_tagging
    stub_tagging_lookup

    post "/documents", {
      'title' => 'HMRC',
      'link' => '/government/organisations/hmrc',
      'slug' => 'hmrc',
      'format' => 'organisation',
      'organisations' => [],
    }.to_json

    assert_document_is_in_rummager({
      "link" => "/government/organisations/hmrc",
      "organisations" => ["hmrc"],
    })
  end

  def test_adding_a_document_to_the_search_index_with_queue
    stub_tagging_lookup

    post "/documents", SAMPLE_DOCUMENT.to_json

    assert_equal 202, last_response.status
    assert_document_is_in_rummager(SAMPLE_DOCUMENT)
  end
end
