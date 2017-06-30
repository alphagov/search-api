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
      "_type" => "manual",
      "content_id" => "6b965b82-2e33-4587-a70c-60204cbb3e29",
      "title" => "TITLE",
      "format" => "answer",
      "content_store_document_type" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
      "licence_identifier" => "1201-5-1",
      "licence_short_description" => "A short description of a licence",
    }.to_json

    assert_document_is_in_rummager({
      "_type" => "manual",
      "content_id" => "6b965b82-2e33-4587-a70c-60204cbb3e29",
      "title" => "TITLE",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
      "navigation_document_supertype" => "guidance",
      "email_document_supertype" => "other",
      "government_document_supertype" => "other",
      "licence_identifier" => "1201-5-1",
      "licence_short_description" => "A short description of a licence",
    }, type: "manual")
  end

  def test_document_type_defaults_to_edition
    publishing_api_has_expanded_links(
      content_id: "9d86d339-44c2-474f-8daf-cb64bed6c0d9",
      expanded_links: {},
    )

    post "/documents", {
      "content_id" => "9d86d339-44c2-474f-8daf-cb64bed6c0d9",
      "link" => "/an-example-answer",
    }.to_json

    assert_document_is_in_rummager({
      "_type" => "edition",
      "content_id" => "9d86d339-44c2-474f-8daf-cb64bed6c0d9",
      "link" => "/an-example-answer",
    }, type: "edition")
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
