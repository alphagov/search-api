require "integration_test_helper"
require "gds_api/test_helpers/publishing_api_v2"

class TaglookupDuringIndexingTest < IntegrationTest
  include GdsApi::TestHelpers::PublishingApiV2

  def setup
    stub_elasticsearch_settings
    create_test_indexes
    reset_content_indexes
  end

  def teardown
    clean_test_indexes
  end

  def test_indexes_document_without_publishing_api_content_unchanged
    publishing_api_has_lookups({})

    post "/documents", {
      "link" => "/something-not-in-publishing-api",
    }.to_json

    assert_document_is_in_rummager(
      "link" => "/something-not-in-publishing-api",
    )
  end

  def test_indexes_document_with_external_url_unchanged
    publishing_api_has_lookups({})

    post "/documents", {
      "link" => "http://example.com/some-link",
    }.to_json

    assert_document_is_in_rummager(
      "link" => "http://example.com/some-link",
    )
  end

  def test_indexes_documents_with_links_from_publishing_api
    publishing_api_has_lookups(
      "/foo/bar" => "DOCUMENT-CONTENT-ID"
    )

    publishing_api_has_expanded_links(
      content_id: "DOCUMENT-CONTENT-ID",
      expanded_links: {
        topics: [
          {
            "content_id" => "TOPIC-CONTENT-ID-1",
            "base_path" => "/topic/my-topic/a",
          },
          {
            "content_id" => "TOPIC-CONTENT-ID-2",
            "base_path" => "/topic/my-topic/b",
          }
        ],
        mainstream_browse_pages: [
          {
            "content_id" => "BROWSE-1",
            "base_path" => "/browse/my-browse/1",
          }
        ],
        organisations: [
          {
            "content_id" => "ORG-1",
            "base_path" => "/government/organisations/my-org/1",
          }
        ],
      }
    )

    post "/documents", {
      "link" => "/foo/bar",
    }.to_json

    assert_document_is_in_rummager(
      "link" => "/foo/bar",
      "specialist_sectors" => ["my-topic/a", "my-topic/b"],
      "mainstream_browse_pages" => ["my-browse/1"],
      "organisations" => ["my-org/1"],
    )
  end

  def test_skips_content_id_lookup_if_it_already_has_a_content_id
    publishing_api_has_expanded_links(
      content_id: "CONTENT-ID-OF-DOCUMENT",
      expanded_links: {
        topics: [
          {
            "content_id" => "TOPIC-CONTENT-ID-1",
            "base_path" => "/topic/my-topic/a",
          }
        ]
      }
    )

    post "/documents", {
      "link" => "/my-base-path",
      "content_id" => "CONTENT-ID-OF-DOCUMENT",
    }.to_json

    assert_document_is_in_rummager(
      "link" => "/my-base-path",
      "content_id" => "CONTENT-ID-OF-DOCUMENT",
      "specialist_sectors" => ["my-topic/a"],
    )
  end
end
