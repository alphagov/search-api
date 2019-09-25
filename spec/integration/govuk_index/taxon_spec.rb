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
    content_id = "c6d82aef-8f85-43b5-8a15-87719916204c"
    document = { "link" => "/transport/all", "content_id" => content_id }

    commit_document("govuk_test", document, id: content_id, type: "taxon")
    expect_document_is_in_rummager(document, id: content_id, index: "govuk_test", type: "taxon")

    payload = { "document_type" => "gone", "payload_version" => 15, "content_id" => content_id }
    @queue.publish(payload.to_json, content_type: "application/json")

    expect_document_missing_in_rummager(id: content_id, index: "govuk_test")
  end
end
