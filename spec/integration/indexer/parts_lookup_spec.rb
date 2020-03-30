require "spec_helper"
require "gds_api/test_helpers/publishing_api_v2"

RSpec.describe "PartslookupDuringIndexingTest" do
  include GdsApi::TestHelpers::PublishingApi

  it "indexes document with parts unchanged" do
    stub_publishing_api_has_lookups(
      "/foo" => "document-content-id",
    )

    stub_publishing_api_has_expanded_links(content_id: "document-content-id", expanded_links: {})

    post "/government_test/documents", {
      "link" => "/foo",
      "parts" => [{ "slug" => "foo", "title" => "bar", "body" => "baz" }],
      "attachments" => [
        { "url" => "/foo/attachment-1", "title" => "attachment 1", "attachment_type" => "html" },
        { "url" => "/foo/attachment-2", "title" => "attachment 2", "attachment_type" => "html" },
        { "url" => "/foo/attachment-3", "title" => "attachment 3", "attachment_type" => "html" },
      ],
    }.to_json

    expect_document_is_in_rummager(
      {
        "link" => "/foo",
        "parts" => [{ "slug" => "foo", "title" => "bar", "body" => "baz" }],
      },
      index: "government_test",
    )
  end

  it "indexes documents with attachments from publishing api" do
    stub_publishing_api_has_lookups(
      "/foo" => "document-content-id",
      "/foo/attachment-1" => "attachment-content-id-1",
      "/foo/attachment-2" => "attachment-content-id-2",
      "/foo/attachment-3" => "attachment-content-id-3",
    )

    stub_publishing_api_has_expanded_links(content_id: "document-content-id", expanded_links: {})

    stub_publishing_api_has_item({ content_id: "attachment-content-id-1", publication_state: "published", details: { body: "<strong>body 1</strong>" } })
    stub_publishing_api_has_item({ content_id: "attachment-content-id-2", publication_state: "published", details: { body: "<em>body 2</em>" } })
    stub_publishing_api_has_item({ content_id: "attachment-content-id-3", publication_state: "published", details: { body: "<p>body 3</p>" } })

    post "/government_test/documents", {
      "link" => "/foo",
      "attachments" => [
        { "url" => "/foo/attachment-1", "title" => "attachment 1", "attachment_type" => "html" },
        { "url" => "/foo/attachment-2", "title" => "attachment 2", "attachment_type" => "html" },
        { "url" => "/foo/attachment-3", "title" => "attachment 3", "attachment_type" => "html" },
      ],
    }.to_json

    expect_document_is_in_rummager(
      {
        "link" => "/foo",
        "parts" => [
          { "slug" => "attachment-1", "title" => "attachment 1", "body" => "body 1" },
          { "slug" => "attachment-2", "title" => "attachment 2", "body" => "body 2" },
          { "slug" => "attachment-3", "title" => "attachment 3", "body" => "body 3" },
        ],
      },
      index: "government_test",
    )
  end

  it "ignores non-html attachments" do
    stub_publishing_api_has_lookups(
      "/foo" => "document-content-id",
      "/foo/attachment-1" => "attachment-content-id-1",
      "/foo/attachment-2" => "attachment-content-id-2",
    )

    stub_publishing_api_has_expanded_links(content_id: "document-content-id", expanded_links: {})

    stub_publishing_api_has_item({ content_id: "attachment-content-id-1", publication_state: "published", details: { body: "<strong>body 1</strong>" } })
    stub_publishing_api_has_item({ content_id: "attachment-content-id-2", publication_state: "published", details: { body: "<em>body 2</em>" } })

    post "/government_test/documents", {
      "link" => "/foo",
      "attachments" => [
        { "url" => "/foo/attachment-1", "title" => "attachment 1", "attachment_type" => "html" },
        { "url" => "/foo/attachment-2", "title" => "attachment 2", "attachment_type" => "html" },
        { "url" => "/foo/attachment-3", "title" => "attachment 3", "attachment_type" => "file" },
      ],
    }.to_json

    expect_document_is_in_rummager(
      {
        "link" => "/foo",
        "parts" => [
          { "slug" => "attachment-1", "title" => "attachment 1", "body" => "body 1" },
          { "slug" => "attachment-2", "title" => "attachment 2", "body" => "body 2" },
        ],
      },
      index: "government_test",
    )
  end
end
