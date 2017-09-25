require 'spec_helper'
load "tasks/message_queue.rake"

RSpec.describe 'MessageProcessorRakeTest' do
  context "when indexing published documents to publishing-api" do
    it "use GovukMessageQueueConsumer::Consumer" do
      statsd_client = Statsd.new
      Services.expects(:statsd_client).returns(statsd_client)

      indexer = Indexer::MessageProcessor.new
      Indexer::MessageProcessor.expects(:new).returns(indexer)

      consumer = mock('consumer')
      consumer.expects(:run).returns(true)

      GovukMessageQueueConsumer::Consumer.expects(:new)
        .with(
          queue_name: "rummager_to_be_indexed",
          processor: indexer,
          statsd_client: statsd_client,
        ).returns(consumer)

      Rake::Task["message_queue:listen_to_publishing_queue"].invoke
    end
  end
end
