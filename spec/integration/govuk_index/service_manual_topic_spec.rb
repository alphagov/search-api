require "spec_helper"

RSpec.describe "Service Manual Topic publishing" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "service_manual_topic.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock
    )

    @queue = @channel.queue("service_manual_topic.test")
    consumer.run
  end

  it "indexes a Service Manual Topic" do
    random_example = generate_random_example(
      schema: "service_manual_topic",
      payload: {
        document_type: "service_manual_topic",
        title: "Service Manual title",
        description: "Service Manual description"
      },
    )

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("service_manual_topic" => :all)

    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = {
      "link" => random_example["base_path"],
      "indexable_content" => nil,
      "title" => random_example["title"],
      "description" => random_example["description"],
      "manual" => "/service-manual"
    }

    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "service_manual_topic")
  end
end
