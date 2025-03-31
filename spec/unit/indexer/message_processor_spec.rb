require "spec_helper"
require "govuk_message_queue_consumer/test_helpers"

RSpec.describe Indexer::MessageProcessor do
  let(:content_item) { generate_random_example }
  let(:message) { GovukMessageQueueConsumer::MockMessage.new(content_item) }
  let(:logger) { Logging.logger[described_class] }

  it_behaves_like "a message queue processor"

  context "when successful" do
    before do
      expect(Indexer::ChangeNotificationProcessor)
        .to receive(:trigger)
        .with(message.payload)
        .and_return(:accepted)
    end

    it "logs some messages" do
      expected_messages = [
        /#{Regexp.escape("Processing message [] (attempt 1/5): {\"content_id\":\"#{content_item['content_id']}\"")}/,
        /Finished processing message/,
      ]

      expected_messages.each do |message|
        expect(logger).to receive(:info).with(message)
      end

      described_class.new.process(message)
    end

    it "increments the statsd counter" do
      expect(Services.statsd_client).to receive(:increment).with("message_queue.indexer.accepted")
      described_class.new.process(message)
    end

    it "acknowledges the message" do
      expect(message).to receive(:ack)
      described_class.new.process(message)
    end
  end

  context "when an error is raised" do
    before do
      expect(Indexer::ChangeNotificationProcessor)
        .to receive(:trigger)
        .with(message.payload)
        .and_raise("oh no")
    end

    it_behaves_like "a retryable queue processor"
  end
end
