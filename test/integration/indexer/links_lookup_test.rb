require "integration_test_helper"
require "gds_api/test_helpers/publishing_api_v2"

class TaglookupDuringIndexingTest < IntegrationTest
  include GdsApi::TestHelpers::PublishingApiV2

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
          },
          {
            "content_id" => "ORG-2",
            "base_path" => "/courts-tribunals/my-court",
          }
        ],
        taxons: [
          {
            "content_id" => "TAXON-1",
            "base_path" => "/alpha-taxonomy/my-taxon-1",
            "title" => "Taxon 1",
            "details" => {
              "internal_name" => "Taxon 1"
            },
            "links" => {}
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
      "organisations" => ["my-org/1", "my-court"],
      "part_of_taxonomy_tree" => ["TAXON-1"],
      "taxons" => ["TAXON-1"],
      "topic_content_ids" => ["TOPIC-CONTENT-ID-1", "TOPIC-CONTENT-ID-2"],
      "mainstream_browse_page_content_ids" => ["BROWSE-1"],
      "organisation_content_ids" => ["ORG-1", "ORG-2"],
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
      "topic_content_ids" => ["TOPIC-CONTENT-ID-1"],
    )
  end

  def test_extracts_parts_of_taxonomy
    grandparent_1_content_id = "22aadc14-9bca-40d9-abb4-4f21f9792a05"
    grandparent_1 = {
      "content_id" => grandparent_1_content_id,
      "base_path" => "/grandparent-1",
      "title" => "Grandparent 1",
      "details" => {
        "internal_name" => "Grandparent 1",
      },
      "links" => {}
    }

    parent_1_content_id = "11aadc14-9bca-40d9-abb4-4f21f9792a05"
    parent_1 = {
      "content_id" => parent_1_content_id,
      "base_path" => "/parent-1",
      "title" => "Parent 1",
      "details" => {
        "internal_name" => "Parent 1",
      },
      "links" => {
        "parent_taxons" => [grandparent_1]
      }
    }

    taxon_1_content_id = "00aadc14-9bca-40d9-abb4-4f21f9792a05"
    taxon_1 = {
      "content_id" => taxon_1_content_id,
      "base_path" => "/this-is-a-taxon",
      "title" => "Taxon 1",
      "details" => {
        "internal_name" => "Taxon 1",
      },
      "links" => {
        "parent_taxons" => [parent_1]
      }
    }

    grandparent_2_content_id = "03aadc14-9bca-40d9-abb4-4f21f9792a05"
    grandparent_2 = {
      "content_id" => grandparent_2_content_id,
      "base_path" => "/grandparent-2",
      "title" => "Grandparent 2",
      "details" => {
        "internal_name" => "Grandparent 2",
      },
      "links" => {}
    }

    parent_2_content_id = "02aadc14-9bca-40d9-abb4-4f21f9792a05"
    parent_2 = {
      "content_id" => parent_2_content_id,
      "base_path" => "/parent-2",
      "title" => "Parent 2",
      "details" => {
        "internal_name" => "Parent 2",
      },
      "links" => {
        "parent_taxons" => [grandparent_2]
      }
    }

    taxon_2_content_id = "01aadc14-9bca-40d9-abb4-4f21f9792a05"
    taxon_2 = {
      "content_id" => taxon_2_content_id,
      "base_path" => "/this-is-also-a-taxon",
      "title" => "Taxon 2",
      "details" => {
        "internal_name" => "Taxon 2",
      },
      "links" => {
        "parent_taxons" => [parent_2]
      }
    }

    publishing_api_has_lookups(
      "/foo/bar" => "DOCUMENT-CONTENT-ID"
    )

    publishing_api_has_expanded_links(
      content_id: "DOCUMENT-CONTENT-ID",
      expanded_links: {
        taxons: [taxon_1, taxon_2],
      }
    )

    post "/documents", {
      "link" => "/foo/bar",
    }.to_json

    assert_document_is_in_rummager(
      "link" => "/foo/bar",
      "part_of_taxonomy_tree" => [
        grandparent_1_content_id, parent_1_content_id, taxon_1_content_id,
        grandparent_2_content_id, parent_2_content_id, taxon_2_content_id,
      ],
      "taxons" => [taxon_1_content_id, taxon_2_content_id],
    )
  end
end
