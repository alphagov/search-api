require "spec_helper"
require "gds_api/test_helpers/publishing_api_v2"

RSpec.describe "TaglookupDuringIndexingTest" do
  include GdsApi::TestHelpers::PublishingApiV2

  it "indexes document without publishing api content unchanged" do
    publishing_api_has_lookups({})

    post "/government_test/documents", {
      "link" => "/something-not-in-publishing-api",
    }.to_json

    expect_document_is_in_rummager(
      { "link" => "/something-not-in-publishing-api" },
      index: "government_test",
    )
  end

  it "indexes document with external url unchanged" do
    publishing_api_has_lookups({})

    post "/government_test/documents", {
      "link" => "http://example.com/some-link",
    }.to_json

    expect_document_is_in_rummager(
      { "link" => "http://example.com/some-link" },
      index: "government_test",
    )
  end

  it "indexes documents with links from publishing api" do
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
        primary_publishing_organisation: [
          {
            "content_id" => "ORG-1",
            "base_path" => "/government/organisations/my-org/1",
          },
        ],
        taxons: [
          {
            "content_id" => "TAXON-1",
            "base_path" => "/alpha-taxonomy/my-taxon-1",
          }
        ],
        facet_values: [
          { "content_id" => "TAG-1" },
          { "content_id" => "TAG-2" }
        ],
        facet_groups: [
          { "content_id" => "TGRP-1" },
          { "content_id" => "TGRP-2" }
        ],
      }
    )

    post "/government_test/documents", {
      "link" => "/foo/bar",
    }.to_json

    expect_document_is_in_rummager(
      {
        "link" => "/foo/bar",
        "specialist_sectors" => ["my-topic/a", "my-topic/b"],
        "mainstream_browse_pages" => ["my-browse/1"],
        "organisations" => ["my-org/1", "my-court"],
        "primary_publishing_organisation" => ["my-org/1"],
        "part_of_taxonomy_tree" => ["TAXON-1"],
        "taxons" => ["TAXON-1"],
        "topic_content_ids" => ["TOPIC-CONTENT-ID-1", "TOPIC-CONTENT-ID-2"],
        "mainstream_browse_page_content_ids" => ["BROWSE-1"],
        "organisation_content_ids" => ["ORG-1", "ORG-2"],
        "facet_groups" => ["TGRP-1", "TGRP-2"],
        "facet_values" => ["TAG-1", "TAG-2"],
      },
      index: "government_test",
    )
  end

  it "skips content id lookup if it already has a content_id" do
    publishing_api_has_expanded_links(
      content_id: "CONTENT-ID-OF-DOCUMENT",
      expanded_links: {
        topics: [
          {
            "content_id" => "TOPIC-CONTENT-ID-1",
            "base_path" => "/topic/my-topic/a",
          }
        ],
      }
    )

    post "/government_test/documents", {
      "link" => "/my-base-path",
      "content_id" => "CONTENT-ID-OF-DOCUMENT",
    }.to_json

    expect_document_is_in_rummager(
      {
        "link" => "/my-base-path",
        "content_id" => "CONTENT-ID-OF-DOCUMENT",
        "specialist_sectors" => ["my-topic/a"],
        "topic_content_ids" => ["TOPIC-CONTENT-ID-1"],
      },
      index: "government_test",
    )
  end

  it "extracts parts of taxonomy" do
    grandparent_1_content_id = "22aadc14-9bca-40d9-abb4-4f21f9792a05"
    grandparent_1 = {
      "content_id" => grandparent_1_content_id,
      "base_path" => "/grandparent-1",
      "title" => "Grandparent 1",
      "links" => {},
    }

    parent_1_content_id = "11aadc14-9bca-40d9-abb4-4f21f9792a05"
    parent_1 = {
      "content_id" => parent_1_content_id,
      "base_path" => "/parent-1",
      "title" => "Parent 1",
      "links" => {
        "parent_taxons" => [grandparent_1],
      },
    }

    taxon_1_content_id = "00aadc14-9bca-40d9-abb4-4f21f9792a05"
    taxon_1 = {
      "content_id" => taxon_1_content_id,
      "base_path" => "/this-is-a-taxon",
      "title" => "Taxon 1",
      "links" => {
        "parent_taxons" => [parent_1],
      },
    }

    grandparent_2_content_id = "03aadc14-9bca-40d9-abb4-4f21f9792a05"
    grandparent_2 = {
      "content_id" => grandparent_2_content_id,
      "base_path" => "/grandparent-2",
      "title" => "Grandparent 2",
      "links" => {},
    }

    parent_2_content_id = "02aadc14-9bca-40d9-abb4-4f21f9792a05"
    parent_2 = {
      "content_id" => parent_2_content_id,
      "base_path" => "/parent-2",
      "title" => "Parent 2",
      "links" => {
        "parent_taxons" => [grandparent_2],
      },
    }

    taxon_2_content_id = "01aadc14-9bca-40d9-abb4-4f21f9792a05"
    taxon_2 = {
      "content_id" => taxon_2_content_id,
      "base_path" => "/this-is-also-a-taxon",
      "title" => "Taxon 2",
      "links" => {
        "parent_taxons" => [parent_2],
      },
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

    post "/government_test/documents", {
      "link" => "/foo/bar",
    }.to_json

    expect_document_is_in_rummager(
      {
        "link" => "/foo/bar",
        "part_of_taxonomy_tree" => [
          grandparent_1_content_id, parent_1_content_id, taxon_1_content_id,
          grandparent_2_content_id, parent_2_content_id, taxon_2_content_id,
        ],
        "taxons" => [taxon_1_content_id, taxon_2_content_id],
      },
      index: "government_test",
    )
  end
end
