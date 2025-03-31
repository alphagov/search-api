module GovukIndex
  class PublishingEventProcessor
    def process(messages)
      messages = Array(messages) # treat a single message as an array with one value

      Services.statsd_client.increment("govuk_index.rabbit-mq-consumed")

      PublishingEventMessageHandler.call(messages.map { |msg| [msg.delivery_info[:routing_key], msg.payload] })

      messages.each(&:ack)
    end
  end
end
