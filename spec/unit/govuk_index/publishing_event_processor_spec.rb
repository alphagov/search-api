require "spec_helper"
require "govuk_message_queue_consumer/test_helpers"

RSpec.describe GovukIndex::PublishingEventProcessor do
  it_behaves_like "a message queue processor"

  it "will process and ack a single message" do
    message = double(
      payload: {
        "base_path" => "/cheese",
        "document_type" => "help_page",
        "title" => "We love cheese",
      },
      delivery_info: {
        routing_key: "routing.key",
      },
    )

    expect(GovukIndex::PublishingEventMessageHandler).to receive(:call).with(
      [["routing.key", message.payload]],
    )

    expect(message).to receive(:ack)

    subject.process(message)
  end

  it "will process and ack an array of messages" do
    message1 = double(
      payload: {
        "base_path" => "/cheese",
        "document_type" => "help_page",
        "title" => "We love cheese",
      },
      delivery_info: {
        routing_key: "routing.key",
      },
    )
    message2 = double(
      payload: {
        "base_path" => "/crackers",
        "document_type" => "help_page",
        "title" => "We love crackers",
      },
      delivery_info: {
        routing_key: "routing.key",
      },
    )

    expect(GovukIndex::PublishingEventMessageHandler).to receive(:call).with(
      [["routing.key", message1.payload], ["routing.key", message2.payload]],
    )
    expect(message1).to receive(:ack)
    expect(message2).to receive(:ack)

    subject.process([message1, message2])
  end
end
