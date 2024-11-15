require "byebug"
module SpecialistDocumentIndex
  class PublishingEventProcessor
    def process(message)
      Services.statsd_client.increment("specialist_document_index.rabbit-mq-consumed")
      payload = message.payload
      # byebug
      IndexSpecialistDocumentJob.perform_async(payload) if Config.specialist_document_types.include? payload["document_type"]
      RemoveSpecialistDocumentJob.perform_async(payload) if Config.unpublishing_document_types.include? payload["document_type"]
      message.ack
    end
  end
end
