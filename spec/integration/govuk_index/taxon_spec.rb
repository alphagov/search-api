require "spec_helper"

RSpec.describe "taxon publishing" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "taxon.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock,
    )

    @queue = @channel.queue("taxon.test")
    consumer.run
  end

  it "indexes a taxon page" do
    random_example = generate_random_example(
      schema: "taxon",
      payload: {
        document_type: "taxon",
        base_path: "/transport/all",
      },
    )

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("taxon" => :all)
    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = { "link" => random_example["base_path"] }
    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "edition")
  end

  it "removes a taxon page" do
    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("taxon" => :all)
    base_path = "/transport/all"
    document = { "link" => base_path, "base_path" => base_path }

    commit_document("govuk_test", document, id: base_path, type: "taxon")
    expect_document_is_in_rummager(document, id: base_path, index: "govuk_test", type: "taxon")

    payload = { "document_type" => "gone", "payload_version" => 15, "base_path" => base_path }
    @queue.publish(payload.to_json, content_type: "application/json")

    expect_document_missing_in_rummager(id: base_path, index: "govuk_test")
  end
end
