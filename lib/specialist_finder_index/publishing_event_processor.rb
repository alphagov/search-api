module SpecialistFinderIndex
  class PublishingEventProcessor
    def process(messages)
      messages = Array(messages) # treat a single message as an array with one value

      Services.statsd_client.increment("specialist_finder_index.rabbit-mq-consumed")
      PublishingEventJob.perform_async(messages.map { |msg| [msg.delivery_info[:routing_key], msg.payload] })
      messages.each(&:ack)
    end
  end
end
