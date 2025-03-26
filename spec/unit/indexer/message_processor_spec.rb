require "spec_helper"

RSpec.describe Indexer::MessageProcessor do
  let(:content_item) { generate_random_example }
  let(:message) { GovukMessageQueueConsumer::MockMessage.new(content_item) }
  let(:logger) { Logging.logger[described_class] }

  context "when successful" do
    before do
      expect(Indexer::ChangeNotificationProcessor)
        .to receive(:trigger)
        .with(message.payload)
        .and_return(:accepted)
    end

    it "logs some messages" do
      expected_messages = [
        /Processing message \[\]: {"content_id":"#{content_item['content_id']}"/,
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

    context "and the message is retryable" do
      it "logs the error" do
        expect(logger).to receive(:error).with(
          /#{content_item['content_id']} scheduled for retry due to error: RuntimeError oh no/,
        )

        described_class.new.process(message)
      end

      it "retries the message" do
        # RetryableQueueMessage#retry calls GovukMessageQueueConsumer::Message#discard, so we need to assert the `discard` method is called
        expect(message).to receive(:discard)
        described_class.new.process(message)
      end
    end

    context "and the message is not retryable" do
      before do
        message.headers[:headers] = { "x-death" => 30.times.map { { "count" => 1 } } }
      end

      it "logs the error" do
        expect(logger).to receive(:error).with(
          /#{content_item['content_id']} ignored after #{described_class::MAX_RETRIES} retries/,
        )

        described_class.new.process(message)
      end

      it "reports the error" do
        expect(GovukError).to receive(:notify).with(RuntimeError, extra: message.payload)
        described_class.new.process(message)
      end

      it "acks the message so it does not retry" do
        expect(message).to receive(:ack)
        described_class.new.process(message)
      end
    end
  end
end
