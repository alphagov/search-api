require "spec_helper"

RSpec.describe "Payload preparation" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "payload_preparer.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock,
    )

    @queue = @channel.queue("payload_preparer.test")
    consumer.run
  end

  context "attachments" do
    context "when the document has parts" do
      it "leaves the parts unchanged" do
        stub_publishing_api_has_lookups(
          "/foo" => "document-content-id",
          "/foo/attachment-1" => "attachment-content-id-1",
          "/foo/attachment-2" => "attachment-content-id-2",
          "/foo/attachment-3" => "attachment-content-id-3",
        )

        stub_publishing_api_has_expanded_links(
          {
            content_id: "document-content-id",
            expanded_links: {},
          },
          with_drafts: false,
        )

        stub_publishing_api_has_item({ content_id: "attachment-content-id-1", publication_state: "published", details: { body: "<strong>body 1</strong>" } })
        stub_publishing_api_has_item({ content_id: "attachment-content-id-2", publication_state: "published", details: { body: "<em>body 2</em>" } })
        stub_publishing_api_has_item({ content_id: "attachment-content-id-3", publication_state: "published", details: { body: "<p>body 3</p>" } })

        random_example = generate_random_example(
          schema: "guide",
          payload: {
            base_path: "/foo",
            document_type: "guide",
          },
        )
        random_example["details"]["parts"] = [
          { "slug" => "foo", "title" => "foo", "body" => [{ "content_type" => "text/html", "content" => "baz" }] },
        ]
        random_example["details"]["attachments"] = [
          { "url" => "/foo/attachment-1", "title" => "attachment 1", "attachment_type" => "html" },
          { "url" => "/foo/attachment-2", "title" => "attachment 2", "attachment_type" => "html" },
          { "url" => "/foo/attachment-3", "title" => "attachment 3", "attachment_type" => "html" },
        ]

        allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("guide" => :all)
        @queue.publish(random_example.to_json, content_type: "application/json")

        expect_document_is_in_rummager(
          {
            "link" => "/foo",
            "parts" => [
              { "slug" => "foo", "title" => "foo", "body" => "baz" },
            ],
            "attachments" => [
              { "title" => "attachment 1", "content" => "body 1" },
              { "title" => "attachment 2", "content" => "body 2" },
              { "title" => "attachment 3", "content" => "body 3" },
            ],
          },
          index: "govuk_test",
        )
      end
    end
    context "when the document doesn't have parts" do
      it "uses HTML attachments for parts" do
        stub_publishing_api_has_lookups(
          "/bar" => "document-content-id",
          "/bar/attachment-1" => "attachment-content-id-1",
          "/bar/attachment-2" => "attachment-content-id-2",
          "/bar/attachment-3" => "attachment-content-id-3",
        )

        stub_publishing_api_has_expanded_links(
          {
            content_id: "document-content-id",
            expanded_links: {},
          },
          with_drafts: false,
        )

        stub_publishing_api_has_item({ content_id: "attachment-content-id-1", publication_state: "published", details: { body: "<strong>body 1</strong>" } })
        stub_publishing_api_has_item({ content_id: "attachment-content-id-2", publication_state: "published", details: { body: "<em>body 2</em>" } })
        stub_publishing_api_has_item({ content_id: "attachment-content-id-3", publication_state: "published", details: { body: "<p>body 3</p>" } })

        random_example = generate_random_example(
          schema: "guide",
          payload: {
            base_path: "/bar",
            document_type: "guide",
          },
        )
        random_example["details"].delete("parts")
        random_example["details"]["attachments"] = [
          { "url" => "/bar/attachment-1", "title" => "attachment 1", "attachment_type" => "html" },
          { "url" => "/bar/attachment-2", "title" => "attachment 2", "attachment_type" => "html" },
          { "url" => "/bar/attachment-3", "title" => "attachment 3", "attachment_type" => "html" },
        ]

        allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("guide" => :all)
        @queue.publish(random_example.to_json, content_type: "application/json")

        expect_document_is_in_rummager(
          {
            "link" => "/bar",
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
          index: "govuk_test",
        )
      end
    end
  end
end
