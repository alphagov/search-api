require 'govuk_index/publishing_event_worker'

module GovukIndex
  class PublishingEventProcessor
    def process(message)
      Services.statsd_client.increment('govuk_index.rabbit-mq-consumed')
      PublishingEventWorker.perform_async(message.delivery_info[:routing_key], message.payload)
      message.ack
    end
  end
end
