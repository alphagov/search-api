require "test_helper"
require "govuk_message_queue_consumer"
require "rake"
require "indexer/message_processor"
load "tasks/message_queue.rake"

class MessageProcessorRakeTest < MiniTest::Unit::TestCase
  context "when indexing published documents to publishing-api" do
    should "use GovukMessageQueueConsumer::Consumer" do
      statsd_client = Statsd.new
      Statsd.expects(:new).returns(statsd_client)

      indexer = Indexer::MessageProcessor.new(statsd_client)
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
