require 'govuk_index/publishing_event_worker'

module GovukIndex
  class PublishingEventProcessor
    def process(message)
      PublishingEventWorker.perform_async(message.payload)
      message.ack
    end
  end
end
