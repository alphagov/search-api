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
    let(:channel) { instance_double(Bunny::Channel) }
    let(:exchange) { instance_double(Bunny::Exchange, name: "published_documents") }

    before do
      allow(Bunny).to receive(:new).and_return(session)
      allow(Bunny::Exchange).to receive(:new).with(channel, :topic, "published_documents").and_return(exchange)
    end

    it "creates the exchanges and queues" do
      queues = [
        {
          name: "search_api_to_be_indexed",
          routing_key: "*.links",
          retry_dlx: instance_double(Bunny::Exchange, name: "search_api_to_be_indexed_retry_dlx"),
          discarded_dlx: instance_double(Bunny::Exchange, name: "search_api_to_be_indexed_discarded_dlx"),
          queues: {
            root: instance_double(Bunny::Queue, bind: nil),
            discarded: instance_double(Bunny::Queue, bind: nil),
            wait_to_retry: instance_double(Bunny::Queue, bind: nil),
          },
        },
        {
          name: "search_api_bulk_reindex",
          routing_key: "*.bulk.reindex",
          retry_dlx: instance_double(Bunny::Exchange, name: "search_api_bulk_reindex_retry_dlx"),
          discarded_dlx: instance_double(Bunny::Exchange, name: "search_api_bulk_reindex_discarded_dlx"),
          queues: {
            root: instance_double(Bunny::Queue, bind: nil),
            discarded: instance_double(Bunny::Queue, bind: nil),
            wait_to_retry: instance_double(Bunny::Queue, bind: nil),
          },
        },
        {
          name: "search_api_govuk_index",
          routing_key: "*.*",
          retry_dlx: instance_double(Bunny::Exchange, name: "search_api_govuk_index_retry_dlx"),
          discarded_dlx: instance_double(Bunny::Exchange, name: "search_api_govuk_index_discarded_dlx"),
          queues: {
            root: instance_double(Bunny::Queue, bind: nil),
            discarded: instance_double(Bunny::Queue, bind: nil),
            wait_to_retry: instance_double(Bunny::Queue, bind: nil),
          },
        },
      ]

      queues.each do |config|
        name = config[:name]

        allow(channel).to receive(:fanout).with("#{name}_retry_dlx").and_return(config[:retry_dlx])
        allow(channel).to receive(:fanout).with("#{name}_discarded_dlx").and_return(config[:discarded_dlx])

        allow(channel)
          .to receive(:queue).with(name, anything)
          .and_return(config[:queues][:root])

        allow(channel)
          .to receive(:queue).with(name)
          .and_return(config[:queues][:discarded])

        allow(channel)
          .to receive(:queue).with("#{name}_wait_to_retry", anything)
          .and_return(config[:queues][:wait_to_retry])
      end

      Rake::Task["message_queue:create_queues"].invoke

      queues.each do |config|
        name = config[:name]
        expect(channel).to have_received(:queue).with(
          name,
          arguments: { "x-dead-letter-exchange" => "#{name}_retry_dlx" },
        )

        expect(channel).to have_received(:queue).with(name)

        expect(channel).to have_received(:queue).with(
          "#{name}_wait_to_retry",
          arguments: {
            "x-dead-letter-exchange" => "#{name}_discarded_dlx",
            "x-message-ttl" => 30_000,
          },
        )

        expect(config[:queues][:root]).to have_received(:bind).with(exchange, routing_key: config[:routing_key])
        expect(config[:queues][:wait_to_retry]).to have_received(:bind).with(config[:retry_dlx])
        expect(config[:queues][:discarded]).to have_received(:bind).with(config[:discarded_dlx])
      end
    end
  end
end
