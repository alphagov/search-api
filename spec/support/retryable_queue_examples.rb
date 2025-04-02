RSpec.shared_examples "a retryable queue processor" do
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
