require "spec_helper"
require "rake"
load "tasks/message_queue.rake"

RSpec.describe Indexer::MessageProcessor, "RakeTest" do
  describe "message_queue:listen_to_publishing_queue" do
    it "uses GovukMessageQueueConsumer::Consumer" do
      indexer = described_class.new
      expect(described_class).to receive(:new).and_return(indexer)

      consumer = double("consumer")
      expect(consumer).to receive(:run).and_return(true)

      logger = Logging.logger[described_class]

      expect(GovukMessageQueueConsumer::Consumer).to receive(:new)
        .with(
          queue_name: "search_api_to_be_indexed",
          processor: indexer,
          logger:,
          worker_threads: 10,
          prefetch: 10,
        ).and_return(consumer)

      Rake::Task["message_queue:listen_to_publishing_queue"].invoke
    end
  end

  describe "message_queue:create_queues" do
    let(:session) do
      instance_double(Bunny::Session, create_channel: channel).tap do |double|
        allow(double).to receive(:start).and_return(double)
      end
    end

    let(:exchange) { instance_double(Bunny::Exchange, name: "published_documents") }
    let(:search_api_to_be_indexed_retry_dlx) { instance_double(Bunny::Exchange, name: "search_api_to_be_indexed_retry_dlx") }
    let(:search_api_to_be_indexed_discarded_dlx) { instance_double(Bunny::Exchange, name: "search_api_to_be_indexed_discarded_dlx") }
    let(:channel) { instance_double(Bunny::Channel) }

    let(:search_api_to_be_indexed_queue) { instance_double(Bunny::Queue, bind: nil) }
    let(:search_api_to_be_indexed_wait_to_retry_queue) { instance_double(Bunny::Queue, bind: nil) }
    let(:search_api_to_be_indexed_discarded_queue) { instance_double(Bunny::Queue, bind: nil) }
    let(:search_api_bulk_reindex_queue) { instance_double(Bunny::Queue, bind: nil) }
    let(:search_api_govuk_index_queue) { instance_double(Bunny::Queue, bind: nil) }

    before do
      allow(Bunny).to receive(:new).and_return(session)
      allow(Bunny::Exchange).to receive(:new).with(channel, :topic, "published_documents").and_return(exchange)
      allow(channel).to receive(:fanout).with("search_api_to_be_indexed_retry_dlx")
        .and_return(search_api_to_be_indexed_retry_dlx)
      allow(channel).to receive(:fanout).with("search_api_to_be_indexed_discarded_dlx")
        .and_return(search_api_to_be_indexed_discarded_dlx)
    end

    it "creates exchanges and queues" do
      allow(channel)
        .to receive(:queue).with("search_api_to_be_indexed", anything)
        .and_return(search_api_to_be_indexed_queue)

      allow(channel)
        .to receive(:queue).with("search_api_to_be_indexed")
        .and_return(search_api_to_be_indexed_discarded_queue)

      allow(channel)
        .to receive(:queue).with("search_api_to_be_indexed_wait_to_retry", anything)
        .and_return(search_api_to_be_indexed_wait_to_retry_queue)

      allow(channel)
        .to receive(:queue).with("search_api_bulk_reindex")
        .and_return(search_api_bulk_reindex_queue)

      allow(channel)
        .to receive(:queue).with("search_api_govuk_index")
        .and_return(search_api_govuk_index_queue)

      Rake::Task["message_queue:create_queues"].invoke

      expect(channel).to have_received(:queue).with(
        "search_api_to_be_indexed",
        arguments: { "x-dead-letter-exchange" => "search_api_to_be_indexed_retry_dlx" },
      )
      expect(channel).to have_received(:queue).with(
        "search_api_to_be_indexed",
      )
      expect(channel).to have_received(:queue).with(
        "search_api_to_be_indexed_wait_to_retry",
        arguments: { "x-dead-letter-exchange" => "search_api_to_be_indexed_discarded_dlx",
                     "x-message-ttl" => 30_000 },
      )
      expect(channel).to have_received(:queue).with("search_api_bulk_reindex")
      expect(channel).to have_received(:queue).with("search_api_govuk_index")

      expect(search_api_to_be_indexed_queue).to have_received(:bind).with(exchange, routing_key: "*.links")
      expect(search_api_bulk_reindex_queue).to have_received(:bind).with(exchange, routing_key: "*.bulk.reindex")
      expect(search_api_govuk_index_queue).to have_received(:bind).with(exchange, routing_key: "*.*")
      expect(search_api_to_be_indexed_wait_to_retry_queue).to have_received(:bind).with(search_api_to_be_indexed_retry_dlx)
      expect(search_api_to_be_indexed_discarded_queue).to have_received(:bind).with(search_api_to_be_indexed_discarded_dlx)
    end
  end
end
