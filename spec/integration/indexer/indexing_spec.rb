require 'spec_helper'

RSpec.describe 'ElasticsearchIndexingTest', tags: ['integration'] do
  include GdsApi::TestHelpers::PublishingApiV2

  SAMPLE_DOCUMENT = {
    "title" => "TITLE",
    "description" => "DESCRIPTION",
    "format" => "answer",
    "link" => "/an-example-answer",
    "indexable_content" => "HERE IS SOME CONTENT"
  }.freeze

  before do
    stub_tagging_lookup
  end

  it "adding_a_document_to_the_search_index" do
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

    expect_document_is_in_rummager({
      "content_id" => "6b965b82-2e33-4587-a70c-60204cbb3e29",
      "title" => "TITLE",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT",
      "navigation_document_supertype" => "guidance",
      "email_document_supertype" => "other",
      "user_journey_document_supertype" => "thing",
      "government_document_supertype" => "other",
      "licence_identifier" => "1201-5-1",
      "licence_short_description" => "A short description of a licence",
    }, type: "manual")
  end

  it "document_type_defaults_to_edition" do
    publishing_api_has_expanded_links(
      content_id: "9d86d339-44c2-474f-8daf-cb64bed6c0d9",
      expanded_links: {},
    )

    post "/documents", {
      "content_id" => "9d86d339-44c2-474f-8daf-cb64bed6c0d9",
      "link" => "/an-example-answer",
    }.to_json

    expect_document_is_in_rummager({
      "content_id" => "9d86d339-44c2-474f-8daf-cb64bed6c0d9",
      "link" => "/an-example-answer",
    }, type: "edition")
  end

  it "tagging_organisations_to_self" do
    post "/documents", {
      "title" => "TITLE",
      "format" => "organisation",
      "slug" => "my-organisation",
      "link" => "/an-example-organisation",
    }.to_json

    expect_document_is_in_rummager({
      "title" => "TITLE",
      "format" => "organisation",
      "slug" => "my-organisation",
      "link" => "/an-example-organisation",
      "organisations" => ["my-organisation"],
    })
  end

  it "start_and_end_dates" do
    post "/documents", {
      "title" => "TITLE",
      "format" => "topical_event",
      "slug" => "/government/topical-events/foo",
      "link" => "/government/topical-events/foo",
      "start_date" => "2016-01-01T00:00:00Z",
      "end_date" => "2017-01-01T00:00:00Z"
    }.to_json

    expect_document_is_in_rummager({
      "title" => "TITLE",
      "format" => "topical_event",
      "slug" => "/government/topical-events/foo",
      "link" => "/government/topical-events/foo",
      "start_date" => "2016-01-01T00:00:00Z",
      "end_date" => "2017-01-01T00:00:00Z"
    })
  end

  it "adding_a_document_to_the_search_index_with_organisation_self_tagging" do
    post "/documents", {
      'title' => 'HMRC',
      'link' => '/government/organisations/hmrc',
      'slug' => 'hmrc',
      'format' => 'organisation',
      'organisations' => [],
    }.to_json

    expect_document_is_in_rummager({
      "link" => "/government/organisations/hmrc",
      "organisations" => ["hmrc"],
    })
  end

  it "adding_a_document_to_the_search_index_with_queue" do
    post "/documents", SAMPLE_DOCUMENT.to_json

    expect(202).to eq(last_response.status)
    expect_document_is_in_rummager(SAMPLE_DOCUMENT)
  end
end
