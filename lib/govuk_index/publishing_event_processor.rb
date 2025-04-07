module GovukIndex
  class PublishingEventProcessor
    MAX_RETRIES = 5

    def initialize
      @logger = Logging.logger[self]
    end

    def process(message)
      message = RetryableQueueMessage.new(message)
      payload = message.payload

      logger.info("Processing message (attempt #{message.retries + 1}/#{MAX_RETRIES}): {\"content_id\":\"#{payload['content_id']}\"}")

      begin
        PublishingEventMessageHandler.call(
          message.delivery_info[:routing_key], message.payload
        )
        message.done
      rescue StandardError => e
        if message.retries < MAX_RETRIES - 1
          logger.error("#{payload['content_id']} scheduled for retry due to error: #{e.class} #{e.message}")

          message.retry
        else
          logger.error("#{payload['content_id']} ignored after #{MAX_RETRIES} retries")
          GovukError.notify(e, extra: payload)
          message.done
        end
      end
    end

  private

    attr_reader :logger
  end
end
