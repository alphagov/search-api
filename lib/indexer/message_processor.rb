require_relative "../../app"
require_relative "exceptions"
require_relative "change_notification_processor"

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
    def process(message)
      with_logging(message) do
        Indexer::ChangeNotificationProcessor.trigger(message.payload)
        message.ack
      end
    rescue ProcessingError => e
      Airbrake.notify_or_ignore(e, parameters: message.payload)
      message.discard
    rescue StandardError => e
      # This is rescue of last resort. If anything goes wrong during the payload
      # processing, we don't want to retry the message really quickly because
      # that might overload elasticsearch or other components. This should be
      # replaced by a retry mechanism with exponential back-off.
      Airbrake.notify_or_ignore(e, parameters: message.payload)
      sleep 1
      message.retry
    end

  private

    def with_logging(message)
      log_payload = message.payload.slice(*%w[
        content_id
        base_path
        document_type
        title
        update_type
        publishing_app
      ])

      puts "Processing message [#{message.delivery_info.delivery_tag}]: #{log_payload.to_json}"

      yield

      puts "Finished processing message [#{message.delivery_info.delivery_tag}]"
    end
  end
end
