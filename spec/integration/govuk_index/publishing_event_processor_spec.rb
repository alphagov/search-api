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
      setup_page_traffic_data(document_count: document_count)

      popularity = 1.0 / ([document_count, document_rank].min + SearchConfig.popularity_rank_offset)

      @queue.publish(random_example.to_json, content_type: "application/json")
      commit_index "govuk_test"

      document = fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")

      expect(popularity).to eq(document["_source"]["popularity"])
    end

    it "discards messages that are invalid" do
      invalid_payload = {
        "title" => "Pitts S-2B, G-SKYD, 21 June 1996",
        "document_type" => "help_page",
      }

      expect(GovukError).to receive(:notify)
      @queue.publish(invalid_payload.to_json, extra: { content_type: "application/json" })

      expect(@queue.message_count).to eq(0)
    end

    it "discards messages that are withdrawn and invalid" do
      invalid_payload = {
        "title" => "Pitts S-2B, G-SKYD, 21 June 1996",
        "document_type" => "gone",
      }

      expect(GovukError).to receive(:notify)
      @queue.publish(invalid_payload.to_json, extra: { content_type: "application/json" })

      expect(@queue.message_count).to eq(0)
    end
  end

  context "test queue handles" do
    it "can save multiple documents in a batch" do
      allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(true)
      random_example_a = generate_random_example(
        payload: { document_type: "help_page", payload_version: 123 },
      )
      random_example_b = generate_random_example(
        payload: { document_type: "help_page", payload_version: 123 },
      )

      message_a = double(:msg1, payload: random_example_a, delivery_info: { routing_key: "big.test" })
      message_b = double(:msg2, payload: random_example_b, delivery_info: { routing_key: "big.test" })

      expect(message_a).to receive(:ack)
      expect(message_b).to receive(:ack)

      GovukIndex::PublishingEventProcessor.new.process([message_a, message_b])

      commit_index "govuk_test"

      document_a = fetch_document_from_rummager(id: random_example_a["base_path"], index: "govuk_test")
      document_b = fetch_document_from_rummager(id: random_example_b["base_path"], index: "govuk_test")

      expect(document_a["_source"]["link"]).to eq(random_example_a["base_path"])
      expect(document_a["_id"]).to eq(random_example_a["base_path"])
      expect(document_a["_source"]["document_type"]).to eq("edition")

      expect(document_b["_source"]["link"]).to eq(random_example_b["base_path"])
      expect(document_b["_id"]).to eq(random_example_b["base_path"])
      expect(document_b["_source"]["document_type"]).to eq("edition")
    end

    it "skips blocklisted formats" do
      logger = double(info: true, debug: true)
      worker = GovukIndex::PublishingEventWorker.new
      allow(worker).to receive(:logger).and_return(logger)

      random_example = generate_random_example(
        schema: "special_route",
        payload: { document_type: "special_route", payload_version: 123, base_path: "/tour" },
      )

      worker.perform([["test.route", random_example]])
      commit_index "govuk_test"

      expect(logger).to have_received(:info).with("test.route -> BLOCKLISTED #{random_example['base_path']} edition")
      expect {
        fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")
      }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
    end

    it "alerts on unknown formats - neither safe or block listed" do
      allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(false)
      allow(GovukIndex::MigratedFormats).to receive(:non_indexable?).and_return(false)

      logger = double(info: true, debug: true)
      worker = GovukIndex::PublishingEventWorker.new
      allow(worker).to receive(:logger).and_return(logger)

      random_example = generate_random_example(
        payload: { document_type: "help_page", payload_version: 123 },
      )

      expect(logger).to receive(:info).with("test.route -> UNKNOWN #{random_example['base_path']} edition")
      worker.perform([["test.route", random_example]])
    end

    it "will consider a format that is both safe and block listed to be blocklisted" do
      allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(true)
      allow(GovukIndex::MigratedFormats).to receive(:non_indexable?).and_return(true)

      logger = double(info: true, debug: true)
      worker = GovukIndex::PublishingEventWorker.new
      allow(worker).to receive(:logger).and_return(logger)

      random_example = generate_random_example(
        payload: { document_type: "help_page", payload_version: 123 },
      )

      worker.perform([["test.route", random_example]])
      expect(logger).to have_received(:info).with("test.route -> BLOCKLISTED #{random_example['base_path']} edition")
    end

    it "can block/safe list specific base_paths within a format" do
      logger = double(info: true, debug: true)
      worker = GovukIndex::PublishingEventWorker.new
      allow(worker).to receive(:logger).and_return(logger)

      homepage_example = generate_random_example(
        schema: "special_route",
        payload: { document_type: "special_route", base_path: "/homepage", payload_version: 123 },
      )
      help_example = generate_random_example(
        schema: "special_route",
        payload: { document_type: "special_route", base_path: "/help", payload_version: 123 },
      )

      worker.perform([["test.route", homepage_example]])
      worker.perform([["test.route", help_example]])
      expect(logger).to have_received(:info).with("test.route -> BLOCKLISTED #{homepage_example['base_path']} edition")
      expect(logger).to have_received(:info).with("test.route -> INDEX #{help_example['base_path']} edition")
    end
  end

  def client(cluster: Cluster.default_cluster)
    @client ||= Services.elasticsearch(cluster: cluster)
  end
end
