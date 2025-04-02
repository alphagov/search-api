require "spec_helper"
require "govuk_message_queue_consumer/test_helpers"

RSpec.describe GovukIndex::PublishingEventProcessor do
  let(:content_item) { generate_random_example }
  let(:message) do
    GovukMessageQueueConsumer::MockMessage.new(
      content_item,
      {},
      { routing_key: "routing.key" },
    )
  end
  let(:logger) { Logging.logger[described_class] }

  it_behaves_like "a message queue processor"

  context "when successful" do
    before do
      expect(GovukIndex::PublishingEventMessageHandler)
        .to receive(:call)
        .with("routing.key", message.payload)
    end

    it "logs a message" do
      expect(logger).to receive(:info).with(
        /#{Regexp.escape("Processing message (attempt 1/5): {\"content_id\":\"#{content_item['content_id']}\"")}/,
      )

      described_class.new.process(message)
    end
  end

  context "when an error is raised" do
    before do
      expect(GovukIndex::PublishingEventMessageHandler)
        .to receive(:call)
        .with("routing.key", message.payload)
        .and_raise("oh no")
    end

    it_behaves_like "a retryable queue processor"
  end
end
