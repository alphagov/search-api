require 'spec_helper'

RSpec.describe 'PublishingEventProcessorTest' do
  it "should_process_and_acknowledge_a_message" do
    message = OpenStruct.new(
      payload: {
        "base_path" => "/cheese",
        "document_type" => "help_page",
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
