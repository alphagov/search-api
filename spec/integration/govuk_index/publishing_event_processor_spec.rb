require "spec_helper"

RSpec.describe "GovukIndex::PublishingEventProcessorTest" do
  context "Testing via fake rabbit queue" do
    before do
      bunny_mock = BunnyMock.new
      @channel = bunny_mock.start.channel

      consumer = GovukMessageQueueConsumer::Consumer.new(
        queue_name: "bigwig.test",
        processor: GovukIndex::PublishingEventProcessor.new,
        rabbitmq_connection: bunny_mock,
      )

      @queue = @channel.queue("bigwig.test")
      consumer.run
    end

    it "saves new documents to elasticsearch" do
      allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(true)
      random_example = generate_random_example(
        payload: { document_type: "help_page", payload_version: 123 },
      )

      @queue.publish(random_example.to_json, content_type: "application/json")
      commit_index "govuk_test"

      document = fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")

      expect(random_example["base_path"]).to eq(document["_source"]["link"])
      expect(random_example["base_path"]).to eq(document["_id"])
      expect(document["_source"]["document_type"]).to eq("edition")

      expect(@queue.message_count).to eq(0)
      expect(@channel.acknowledged_state[:acked].count).to eq(1)
    end

    it "includes popularity data when available" do
      allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(true)
      random_example = generate_random_example(
        payload: { document_type: "help_page", payload_version: 123 },
      )

      document_count = 4
      document_rank = 2
      insert_document("page-traffic_test", { rank_14: document_rank, path_components: [random_example["base_path"]] }, id: random_example["base_path"], type: "page-traffic")
      setup_page_traffic_data(document_count:)

      popularity = 1.0 / ([document_count, document_rank].min + SearchConfig.popularity_rank_offset)

      @queue.publish(random_example.to_json, content_type: "application/json")
      commit_index "govuk_test"

      document = fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")

      expect(popularity).to eq(document["_source"]["popularity"])
    end

    it "discards messages that are invalid" do
      invalid_example = generate_random_example(
        schema: "external_content",
        payload: {
          title: "Pitts S-2B, G-SKYD, 21 June 1996",
          document_type: "external_content",
          details: { url: "" },
        },
      )

      @queue.publish(invalid_example.to_json, content_type: "application/json")
      expect(@channel.acknowledged_state[:rejected].count).to eq(1)
    end

    it "discards messages that are withdrawn and invalid" do
      invalid_payload = {
        "title" => "Pitts S-2B, G-SKYD, 21 June 1996",
        "document_type" => "gone",
      }

      expect(GovukError).to receive(:notify)
      @queue.publish(invalid_payload.to_json, content_type: "application/json")

      expect(@queue.message_count).to eq(0)
    end
  end

  context "test queue handles" do
    it "skips blocklisted formats" do
      logger = double(info: true, debug: true)

      random_example = generate_random_example(
        schema: "special_route",
        payload: { document_type: "special_route", payload_version: 123, base_path: "/tour" },
      )

      handler = GovukIndex::PublishingEventMessageHandler.new("test.route", random_example)
      allow(handler).to receive(:logger).and_return(logger)

      handler.call
      commit_index "govuk_test"

      expect(logger).to have_received(:info).with("test.route -> BLOCKLISTED #{random_example['base_path']} edition (non-indexable)")
      expect {
        fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")
      }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
    end

    it "alerts on unknown formats - neither safe or block listed" do
      allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(false)
      allow(GovukIndex::MigratedFormats).to receive(:non_indexable?).and_return(false)

      logger = double(info: true, debug: true)
      random_example = generate_random_example(
        payload: { document_type: "help_page", payload_version: 123 },
      )
      handler = GovukIndex::PublishingEventMessageHandler.new("test.route", random_example)
      allow(handler).to receive(:logger).and_return(logger)

      expect(logger).to receive(:info).with("test.route -> UNKNOWN #{random_example['base_path']} edition")
      handler.call
    end

    it "will consider a format that is both safe and block listed to be blocklisted" do
      allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(true)
      allow(GovukIndex::MigratedFormats).to receive(:non_indexable?).and_return(true)

      logger = double(info: true, debug: true)
      random_example = generate_random_example(
        payload: { document_type: "help_page", payload_version: 123 },
      )
      handler = GovukIndex::PublishingEventMessageHandler.new("test.route", random_example)
      allow(handler).to receive(:logger).and_return(logger)

      handler.call
      expect(logger).to have_received(:info).with("test.route -> BLOCKLISTED #{random_example['base_path']} edition (non-indexable)")
    end

    it "can block/safe list specific base_paths within a format" do
      logger = double(info: true, debug: true)

      homepage_example = generate_random_example(
        schema: "special_route",
        payload: { document_type: "special_route", base_path: "/homepage", payload_version: 123 },
      )
      handler = GovukIndex::PublishingEventMessageHandler.new("test.route", homepage_example)
      allow(handler).to receive(:logger).and_return(logger)
      handler.call
      expect(logger).to have_received(:info).with("test.route -> BLOCKLISTED #{homepage_example['base_path']} edition (non-indexable)")

      help_example = generate_random_example(
        schema: "special_route",
        payload: { document_type: "special_route", base_path: "/help", payload_version: 123 },
      )
      handler = GovukIndex::PublishingEventMessageHandler.new("test.route", help_example)
      allow(handler).to receive(:logger).and_return(logger)
      handler.call
      expect(logger).to have_received(:info).with("test.route -> INDEX #{help_example['base_path']} edition")
    end
  end

  def client(cluster: Cluster.default_cluster)
    @client ||= Services.elasticsearch(cluster:)
  end
end
