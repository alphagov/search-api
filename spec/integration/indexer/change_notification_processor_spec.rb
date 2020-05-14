require "spec_helper"

RSpec.describe "ChangeNotificationProcessorTest" do
  it "triggering a reindex" do
    stub_publishing_api_has_lookups(
      "/foo" => "DOCUMENT-CONTENT-ID",
    )

    stub_publishing_api_has_expanded_links(
      content_id: "DOCUMENT-CONTENT-ID",
      expanded_links: {},
    )

    post "/government_test/documents",
         {
           "title" => "Foo",
           "link" => "/foo",
         }.to_json

    commit_index("government_test")

    expect_document_is_in_rummager(
      {
        "link" => "/foo",
        "mainstream_browse_pages" => [],
      },
      index: "government_test",
    )

    stub_publishing_api_has_expanded_links(
      content_id: "DOCUMENT-CONTENT-ID",
      expanded_links: {
        mainstream_browse_pages: [{
          title: "Bla",
          base_path: "/browse/my-browse",
        }],
      },
    )

    Indexer::ChangeNotificationProcessor.trigger({
      "base_path" => "/foo",
    })

    commit_index("government_test")

    expect_document_is_in_rummager(
      {
        "link" => "/foo",
        "mainstream_browse_pages" => %w[my-browse],
      },
      index: "government_test",
    )
  end
end
