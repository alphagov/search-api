module GovukIndex
  class PublishingEventProcessor
    def process(messages)
      messages = Array(messages) # treat a single message as an array with one value

      Services.statsd_client.increment("govuk_index.rabbit-mq-consumed")

      bulk_reindex_messages, default_messages = messages.partition do |msg|
        msg.delivery_info[:routing_key].end_with?(".bulk.reindex")
      end

      PublishingEventJob.set(queue: "bulk").perform_async(bulk_reindex_messages.map { |msg| [msg.delivery_info[:routing_key], msg.payload] })
      PublishingEventJob.perform_async(default_messages.map { |msg| [msg.delivery_info[:routing_key], msg.payload] })
      messages.each(&:ack)
    end
  end
end
