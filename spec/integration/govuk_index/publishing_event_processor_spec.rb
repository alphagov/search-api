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

  it "indexed with a format of smart answers when publishing app is smart answers" do
    allow(GovukIndex::MigratedFormats).to receive(:indexable?).and_return(true)
    random_example = generate_random_example(
      schema: 'transaction',
      payload: { document_type: "transaction", payload_version: 123, publishing_app: "smartanswers" },
    )

    @queue.publish(random_example.to_json, content_type: "application/json")
    commit_index 'govuk_test'

    document = fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test", type: 'edition')
    expect(document["_source"]["format"]).to eq("smart-answer")
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

  def client
    @client ||= Services::elasticsearch(hosts: SearchConfig.instance.base_uri)
  end
end
