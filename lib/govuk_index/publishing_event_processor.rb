module GovukIndex
  class PublishingEventProcessor
    def process(message)
      Services.statsd_client.increment('govuk_index.rabbit-mq-consumed')
      PublishingEventWorker.perform_async(message.delivery_info[:routing_key], JSON.parse(message.payload))
      message.ack
    end
  end
end
