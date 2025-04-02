# MessageProcessor
#
# This class is instantiated by the rake task and passed to the message queue
# consumer.

# The consumer is currently using the message queue as a notification
# mechanism. When it gets a message that some content has changed, it simply
# re-indexes a document, which (among other things) triggers a new lookup of
# the links from the publishing-api.
module Indexer
  class MessageProcessor
    MAX_RETRIES = 5

    def initialize
      @logger = Logging.logger[self]
    end

    def process(queue_message)
      message = ::RetryableQueueMessage.new(queue_message)
      payload = message.payload

      with_logging(message) do
        indexing_status = Indexer::ChangeNotificationProcessor.trigger(message.payload)
        Services.statsd_client.increment("message_queue.indexer.#{indexing_status}")
        message.done
      end
    rescue StandardError => e
      if message.retries < MAX_RETRIES
        logger.error("#{payload['content_id']} scheduled for retry due to error: #{e.class} #{e.message}")

        message.retry
      else
        logger.error("#{payload['content_id']} ignored after #{MAX_RETRIES} retries")
        GovukError.notify(e, extra: payload)
        message.done
      end
    end

  private

    attr_reader :logger

    def with_logging(message)
      log_payload = message.payload.slice("content_id", "base_path", "document_type", "title", "update_type", "publishing_app")

      logger.info "Processing message [#{message.delivery_info.delivery_tag}]: #{log_payload.to_json}"
      puts "Processing message [#{message.delivery_info.delivery_tag}]: #{log_payload.to_json}"

      yield

      logger.info "Finished processing message [#{message.delivery_info.delivery_tag}]"
      puts "Finished processing message [#{message.delivery_info.delivery_tag}]"
    end
  end
end
