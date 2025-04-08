require "spec_helper"

RSpec.describe "external content publishing" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "external_content.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock,
    )

    @queue = @channel.queue("external_content.test")
    consumer.run
  end

  it "indexes a page of external content" do
    random_example = generate_random_example(
      schema: "external_content",
      payload: {
        document_type: "external_content",
      },
      details: {
        hidden_search_terms: ["some, search, keywords"],
      },
    )

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("recommended-link" => :all)

    @queue.publish(random_example.to_json, content_type: "application/json")

    content_id = random_example["content_id"]
    expected_document = {
      "link" => random_example["details"]["url"],
      "format" => "recommended-link",
      "title" => random_example["title"],
      "description" => random_example["description"],
      "indexable_content" => "some, search, keywords",
    }

    expect_document_is_in_rummager(expected_document, id: content_id, index: "govuk_test", type: "edition")
  end

  it "removes a page of external content" do
    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("recommended-link" => :all)

    url = "https://www.nhs.uk"
    base_path = "/test"
    document = { "link" => url, "base_path" => base_path }
    commit_document("govuk_test", document, id: base_path, type: "recommended-link")
    expect_document_is_in_rummager(document, id: base_path, index: "govuk_test", type: "recommended-link")

    payload = {
      "document_type" => "gone",
      "payload_version" => 15,
      "base_path" => base_path,
    }
    @queue.publish(payload.to_json, content_type: "application/json")

    expect_document_missing_in_rummager(id: base_path, index: "govuk_test")
  end
end
