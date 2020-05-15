require "spec_helper"
require "gds_api/test_helpers/publishing_api_v2"

RSpec.describe "PartslookupDuringIndexingTest" do
  include GdsApi::TestHelpers::PublishingApi

  before do
    stub_publishing_api_has_lookups(
      "/foo" => "document-content-id",
      "/foo/attachment-1" => "attachment-content-id-1",
      "/foo/attachment-2" => "attachment-content-id-2",
      "/foo/attachment-3" => "attachment-content-id-3",
      "/bar/attachment-4" => "attachment-content-id-4",
      "/baz/attachment-5" => "attachment-content-id-5",
    )

    stub_publishing_api_has_expanded_links(content_id: "document-content-id", expanded_links: {})

    stub_publishing_api_has_item({ content_id: "attachment-content-id-1", publication_state: "published", details: { body: "<strong>body 1</strong>" } })
    stub_publishing_api_has_item({ content_id: "attachment-content-id-2", publication_state: "published", details: { body: "<em>body 2</em>" } })
    stub_publishing_api_has_item({ content_id: "attachment-content-id-3", publication_state: "published", details: { body: "<p>body 3</p>" } })
    stub_publishing_api_has_item({ content_id: "attachment-content-id-4", publication_state: "published", details: { body: "body 4" } })
    stub_publishing_api_has_item({ content_id: "attachment-content-id-5", publication_state: "published", details: { body: "body 5" } })
  end

  it "indexes document with parts unchanged" do
    post "/government_test/documents",
         {
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
        "attachments" => [
          { "title" => "attachment 1", "content" => "body 1" },
          { "title" => "attachment 2", "content" => "body 2" },
          { "title" => "attachment 3", "content" => "body 3" },
        ],
      },
      index: "government_test",
    )
  end

  it "indexes documents with attachments from publishing api" do
    post "/government_test/documents",
         {
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
        "attachments" => [
          { "title" => "attachment 1", "content" => "body 1" },
          { "title" => "attachment 2", "content" => "body 2" },
          { "title" => "attachment 3", "content" => "body 3" },
        ],
      },
      index: "government_test",
    )
  end

  it "ignores non-html attachments" do
    post "/government_test/documents",
         {
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
        "attachments" => [
          { "title" => "attachment 1", "content" => "body 1" },
          { "title" => "attachment 2", "content" => "body 2" },
          { "title" => "attachment 3" },
        ],
      },
      index: "government_test",
    )
  end

  it "ignores attachments with a locale given that isn't 'en'" do
    post "/government_test/documents",
         {
           "link" => "/foo",
           "attachments" => [
             { "url" => "/foo/attachment-1", "title" => "attachment 1", "attachment_type" => "html" },
             { "url" => "/foo/attachment-2", "title" => "attachment 2", "attachment_type" => "html", "locale" => "en" },
             { "url" => "/foo/attachment-3", "title" => "attachment 3", "attachment_type" => "file", "locale" => "cy" },
           ],
         }.to_json

    expect_document_is_in_rummager(
      {
        "link" => "/foo",
        "parts" => [
          { "slug" => "attachment-1", "title" => "attachment 1", "body" => "body 1" },
          { "slug" => "attachment-2", "title" => "attachment 2", "body" => "body 2" },
        ],
        "attachments" => [
          { "title" => "attachment 1", "content" => "body 1" },
          { "title" => "attachment 2", "content" => "body 2" },
        ],
      },
      index: "government_test",
    )
  end

  it "ignores attachments where the URL doesn't match the parent/slug format" do
    post "/government_test/documents",
         {
           "link" => "/foo",
           "attachments" => [
             { "url" => "/foo/attachment-1", "title" => "attachment 1", "attachment_type" => "html" },
             { "url" => "/bar/attachment-4", "title" => "attachment 4", "attachment_type" => "html" },
             { "url" => "/baz/attachment-5", "title" => "attachment 5", "attachment_type" => "html" },
           ],
         }.to_json

    expect_document_is_in_rummager(
      {
        "link" => "/foo",
        "parts" => [
          { "slug" => "attachment-1", "title" => "attachment 1", "body" => "body 1" },
        ],
        "attachments" => [
          { "title" => "attachment 1", "content" => "body 1" },
          { "title" => "attachment 4", "content" => "body 4" },
          { "title" => "attachment 5", "content" => "body 5" },
        ],
      },
      index: "government_test",
    )
  end

  it "treats attachments of unspecified type or URL as not HTML" do
    post "/government_test/documents",
         {
           "link" => "/foo",
           "attachments" => [
             { "title" => "attachment 1", "attachment_type" => "html" },
             { "url" => "/foo/attachment-2", "title" => "attachment 2" },
           ],
         }.to_json

    expect_document_is_in_rummager(
      {
        "link" => "/foo",
        "parts" => nil,
        "attachments" => [
          { "title" => "attachment 2" },
        ],
      },
      index: "government_test",
    )
  end
end
