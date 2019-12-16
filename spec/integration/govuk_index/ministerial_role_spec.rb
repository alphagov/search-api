require "spec_helper"

RSpec.describe "Ministerial role publishing" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "ministerial_roles.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock,
    )

    @queue = @channel.queue("ministerial_roles.test")
    consumer.run
  end

  it "indexes a ministerial role" do
    random_example = generate_random_example(
      schema: "role",
      payload: {
        document_type: "ministerial_role",
        base_path: "/government/ministers/prime-minister",
        description: "An important person.",
      },
    )

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("ministerial_role" => :all)

    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = {
      "link" => random_example["base_path"],
      "description" => "An important person.",
      "slug" => "prime-minister",
    }

    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "edition")
  end
end
