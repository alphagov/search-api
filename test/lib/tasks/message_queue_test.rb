require "test_helper"
require "govuk_message_queue_consumer"
require "./lib/indexer/index_documents"
load "./lib/tasks/message_queue.rake"

class MessageProcessorRakeTest < Test::Unit::TestCase
  context "when indexing published documents to publishing-api" do
    should "use GovukMessageQueueConsumer::Consumer" do
      indexer = Indexer::MessageProcessor.new
      Indexer::MessageProcessor.expects(:new).returns(indexer)

      statsd_client = Statsd.new
      Statsd.expects(:new).returns(statsd_client)

      consumer = mock('consumer')
      consumer.expects(:run).returns(true)

      GovukMessageQueueConsumer::Consumer.expects(:new)
        .with(
          queue_name: "rummager_to_be_indexed",
          processor: indexer,
          statsd_client: statsd_client,
        ).returns(consumer)

      Rake::Task["message_queue:index_documents_from_publishing_api"].invoke
    end
  end
end
