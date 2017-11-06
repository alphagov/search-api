module GovukIndex
  class PublishingEventProcessor
    def process(message, worker: PublishingEventWorker)
      Services.statsd_client.increment('govuk_index.rabbit-mq-consumed')
      worker.perform_async(message.delivery_info[:routing_key], message.payload)
      message.ack
    end
  end
end
