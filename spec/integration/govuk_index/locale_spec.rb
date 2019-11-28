require "spec_helper"

RSpec.describe "locales" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "locale.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock,
    )

    @queue = @channel.queue("locale.test")
    consumer.run
  end

  it "indexes pages missing a locale" do
    random_example = generate_random_example(
      schema: "taxon",
      payload: {
        document_type: "taxon",
        base_path: "/transport/magical/apparition",
      },
    )
    random_example.delete("locale")

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("taxon" => :all)
    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = { "link" => random_example["base_path"] }
    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "edition")
  end

  it "indexes English pages" do
    random_example = generate_random_example(
      schema: "taxon",
      payload: {
        document_type: "taxon",
        base_path: "/transport/magical/broomstick",
      },
    )
    random_example["locale"] = "en"

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("taxon" => :all)
    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = { "link" => random_example["base_path"] }
    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "edition")
  end

  it "does not index non-English pages" do
    random_example = generate_random_example(
      schema: "taxon",
      payload: {
        document_type: "taxon",
        base_path: "/transport/magical/floo-network",
      },
    )
    random_example["locale"] = "cy"

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("taxon" => :all)
    @queue.publish(random_example.to_json, content_type: "application/json")

    expect_document_missing_in_rummager(id: random_example["base_path"], index: "govuk_test")
  end
end
