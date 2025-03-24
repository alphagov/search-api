RSpec.describe RetryableQueueMessage do
  describe "#done" do
    it "sets the queue message to acked" do
      queue_message = create_mock_message("message")
      instance = described_class.new(queue_message)
      expect { instance.done }.to change(queue_message, :acked?).to(true)
    end
  end

  describe "#retry" do
    it "sets the queue message to discarded" do
      queue_message = create_mock_message("message")
      instance = described_class.new(queue_message)
      expect { instance.retry }.to change(queue_message, :discarded?).to(true)
    end
  end

  describe "#retries" do
    it "returns 0 for a queue message with no x-death headers" do
      queue_message = create_mock_message("message")
      instance = described_class.new(queue_message)
      expect(instance.retries).to eq(0)
    end

    it "collates the counts from x-death headers and divides by 2 to get actual retries count" do
      queue_message = create_mock_message("message", {
        headers: {
          "x-death" => [
            { "count" => 2, "reason" => "expired", "queue" => "govuk_chat_published_documents_delay_retry" },
            { "count" => 2, "reason" => "rejected", "queue" => "govuk_chat_published_documents" },
          ],
        },
      })
      instance = described_class.new(queue_message)
      expect(instance.retries).to eq(2)
    end
  end

  def create_mock_message(...)
    GovukMessageQueueConsumer::MockMessage.new(...)
  end
end
