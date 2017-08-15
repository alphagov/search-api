require 'test_helper'

class PublishingEventProcessorTest < Minitest::Test
  def test_should_process_and_acknowledge_a_message
    message = OpenStruct.new(
      payload: {
        "base_path" => "/cheese",
        "document_type" => "cheddar",
        "title" => "We love cheese"
      },
      delivery_info: {
        routing_key: 'routing.key'
      }
    )

    GovukIndex::PublishingEventWorker.expects(:perform_async).with('routing.key', message.payload)
    message.expects(:ack)

    GovukIndex::PublishingEventProcessor.new.process(message)
  end
end
