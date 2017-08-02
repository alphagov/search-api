require "test_helper"
require 'govuk_index/publishing_event_processor'
require 'govuk_index/publishing_event_worker'

class PublishingEventProcessorTest < Minitest::Test
  def test_should_process_and_acknowledge_a_message
    message = OpenStruct.new(
      payload: {
        "base_path" => "/cheese",
        "document_type" => "cheddar",
        "title" => "We love cheese"
      }
    )

    GovukIndex::PublishingEventWorker.expects(:perform_async).with(message.payload)
    message.expects(:ack)

    GovukIndex::PublishingEventProcessor.new.process(message)
  end
end
