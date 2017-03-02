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
    super

    stub_tagging_lookup
  end

  def test_adding_a_document_to_the_search_index
    publishing_api_has_expanded_links(
      content_id: "6b965b82-2e33-4587-a70c-60204cbb3e29",
      expanded_links: {},
    )

    post "/documents", {
      "content_id" => "6b965b82-2e33-4587-a70c-60204cbb3e29",
      "title" => "TITLE",
      "format" => "answer",
      "content_store_document_type" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
    }.to_json

    assert_document_is_in_rummager({
      "content_id" => "6b965b82-2e33-4587-a70c-60204cbb3e29",
      "title" => "TITLE",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
      "navigation_document_supertype" => "guidance",
    })
  end

  def test_tagging_organisations_to_self
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

  def test_start_and_end_dates
    post "/documents", {
      "title" => "TITLE",
      "format" => "topical_event",
      "slug" => "/government/topical-events/foo",
      "link" => "/government/topical-events/foo",
      "start_date" => "2016-01-01T00:00:00Z",
      "end_date" => "2017-01-01T00:00:00Z"
    }.to_json

    assert_document_is_in_rummager({
      "title" => "TITLE",
      "format" => "topical_event",
      "slug" => "/government/topical-events/foo",
      "link" => "/government/topical-events/foo",
      "start_date" => "2016-01-01T00:00:00Z",
      "end_date" => "2017-01-01T00:00:00Z"
    })
  end

  def test_adding_a_document_to_the_search_index_with_organisation_self_tagging
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
    post "/documents", SAMPLE_DOCUMENT.to_json

    assert_equal 202, last_response.status
    assert_document_is_in_rummager(SAMPLE_DOCUMENT)
  end
end
