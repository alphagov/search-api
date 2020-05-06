require "spec_helper"

RSpec.describe "Collections publishing" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "collections.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock,
    )

    @queue = @channel.queue("collections.test")
    consumer.run
  end

  it "indexes a mainstream browse page" do
    random_example = generate_random_example(
      schema: "mainstream_browse_page",
      payload: {
        document_type: "mainstream_browse_page",
        description: "Mainstream browse page description",
        base_path: "/browse/benefits",
      },
    )

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("mainstream_browse_page" => :all)

    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = {
      "link" => random_example["base_path"],
      "indexable_content" => nil,
      "slug" => "benefits",
    }

    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "edition")
  end

  it "indexes a specialist sector page" do
    random_example = generate_random_example(
      schema: "topic",
      payload: {
        document_type: "topic",
        description: "Specialist sector page description",
        base_path: "/topic/benefits-credits",
      },
    )

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("specialist_sector" => :all)

    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = {
      "link" => random_example["base_path"],
      "indexable_content" => nil,
      "slug" => "benefits-credits",
    }
    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "edition")
  end
end
