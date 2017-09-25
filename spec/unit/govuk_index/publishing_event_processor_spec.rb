require 'spec_helper'

RSpec.describe 'PublishingEventProcessorTest' do
  it "should_process_and_acknowledge_a_message" do
    message = double(
      payload: {
        "base_path" => "/cheese",
        "document_type" => "help_page",
        "title" => "We love cheese"
      },
      delivery_info: {
        routing_key: 'routing.key'
      }
    )

    expect(GovukIndex::PublishingEventWorker).to receive(:perform_async).with('routing.key', message.payload)
    expect(message).to receive(:ack)

    GovukIndex::PublishingEventProcessor.new.process(message)
  end
end
