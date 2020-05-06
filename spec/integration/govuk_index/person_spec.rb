require "spec_helper"

RSpec.describe "Person publishing" do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "people.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock,
    )

    @queue = @channel.queue("people.test")
    consumer.run
  end

  let(:role_appointments) do
    [
      {
        "content_id" => SecureRandom.uuid,
        "title" => "Prime Minister",
        "locale" => "en",
      },
    ]
  end

  it "indexes a person" do
    random_example = generate_random_example(
      schema: "person",
      payload: {
        document_type: "person",
        base_path: "/government/people/mark-smith",
        description: "A person.",
        expanded_links: {
          role_appointments: role_appointments,
        },
      },
    )

    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("person" => :all)

    @queue.publish(random_example.to_json, content_type: "application/json")

    expected_document = {
      "link" => random_example["base_path"],
      "role_appointments" => [role_appointments.first["content_id"]],
      "description" => "A person.",
      "slug" => "mark-smith",
    }

    expect_document_is_in_rummager(expected_document, index: "govuk_test", type: "person")
  end
end
