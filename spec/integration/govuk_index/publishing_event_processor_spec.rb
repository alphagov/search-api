require 'spec_helper'

RSpec.describe 'GovukIndex::PublishingEventProcessorTest' do
  before do
    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "bigwig.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock
    )

    @queue = @channel.queue("bigwig.test")
    consumer.run
  end

  it "should_save_new_document_to_elasticsearch" do
    allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(true)
    random_example = generate_random_example(
      payload: { document_type: "help_page", payload_version: 123 },
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" }
    )

    @queue.publish(random_example.to_json, content_type: "application/json")
    commit_index 'govuk_test'

    document = fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")

    expect(random_example["base_path"]).to eq(document["_source"]["link"])
    expect(random_example["base_path"]).to eq(document["_id"])
    expect(document["_type"]).to eq("edition")

    expect(@queue.message_count).to eq(0)
    expect(@channel.acknowledged_state[:acked].count).to eq(1)
  end

  it "should_include_popularity_when_available" do
    allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(true)
    random_example = generate_random_example(
      payload: { document_type: "help_page", payload_version: 123 },
      regenerate_if: ->(example) { example["publishing_app"] == "smartanswers" }
    )

    document_count = 4
    document_rank = 2
    insert_document("page-traffic_test", { rank_14: document_rank, path_components: [random_example["base_path"]] }, id: random_example["base_path"], type: "page-traffic")
    setup_page_traffic_data(document_count: document_count)

    popularity = 1.0 / ([document_count, document_rank].min + SearchConfig.instance.popularity_rank_offset)

    @queue.publish(random_example.to_json, content_type: "application/json")
    commit_index 'govuk_test'

    document = fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")

    expect(popularity).to eq(document["_source"]["popularity"])
  end

  it "should_discard_message_when_invalid" do
    invalid_payload = {
      "title" => "Pitts S-2B, G-SKYD, 21 June 1996",
      "document_type" => "help_page",
    }

    expect(GovukError).to receive(:notify)
    @queue.publish(invalid_payload.to_json, extra: { content_type: "application/json" })

    expect(@queue.message_count).to eq(0)
  end

  it "should_discard_message_when_withdrawn_and_invalid" do
    invalid_payload = {
      "title" => "Pitts S-2B, G-SKYD, 21 June 1996",
      "document_type" => "gone",
    }

    expect(GovukError).to receive(:notify)
    @queue.publish(invalid_payload.to_json, extra: { content_type: "application/json" })

    expect(@queue.message_count).to eq(0)
  end

  it "skips blacklisted formats" do
    logger = double(info: true, debug: true)
    worker = GovukIndex::PublishingEventWorker.new
    allow(worker).to receive(:logger).and_return(logger)

    random_example = generate_random_example(
      schema: 'generic_with_external_related_links',
      payload: { document_type: "smart_answer", payload_version: 123 },
    )

    expect(logger).to receive(:info).with("test.route -> BLACKLISTED #{random_example['base_path']} 'unmapped type'")
    worker.perform('test.route', random_example)
    commit_index 'govuk_test'

    expect {
      fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")
    }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
  end

  it "alerts on unknown formats - neither white or black listed" do
    allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(false)
    allow(GovukIndex::MigratedFormats).to receive(:non_indexable?).and_return(false)

    logger = double(info: true, debug: true)
    worker = GovukIndex::PublishingEventWorker.new
    allow(worker).to receive(:logger).and_return(logger)

    random_example = generate_random_example(
      payload: { document_type: "help_page", payload_version: 123 },
    )

    expect(logger).to receive(:info).with("test.route -> UNKNOWN #{random_example['base_path']} edition")
    worker.perform('test.route', random_example)
  end

  it "will consider a format that is both white and black listed to be blacklisted" do
    allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(true)
    allow(GovukIndex::MigratedFormats).to receive(:non_indexable?).and_return(true)

    logger = double(info: true, debug: true)
    worker = GovukIndex::PublishingEventWorker.new
    allow(worker).to receive(:logger).and_return(logger)

    random_example = generate_random_example(
      payload: { document_type: "help_page", payload_version: 123 },
    )

    expect(logger).to receive(:info).with("test.route -> BLACKLISTED #{random_example['base_path']} edition")
    worker.perform('test.route', random_example)
  end

  it "can black/white list specific base_paths within a format" do
    logger = double(info: true, debug: true)
    worker = GovukIndex::PublishingEventWorker.new
    allow(worker).to receive(:logger).and_return(logger)

    homepage_example = generate_random_example(
      schema: 'special_route',
      payload: { document_type: "special_route", base_path: '/homepage', payload_version: 123 },
    )
    help_example = generate_random_example(
      schema: 'special_route',
      payload: { document_type: "special_route", base_path: '/help', payload_version: 123 },
    )

    expect(logger).to receive(:info).with("test.route -> BLACKLISTED #{homepage_example['base_path']} edition")
    expect(logger).to receive(:info).with("test.route -> INDEX #{help_example['base_path']} edition")
    worker.perform('test.route', homepage_example)
    worker.perform('test.route', help_example)
  end

  def client
    @client ||= Services::elasticsearch(hosts: SearchConfig.instance.base_uri)
  end
end
