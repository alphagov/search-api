require 'integration_test_helper'

class GovukIndex::PublishingEventProcessorTest < IntegrationTest
  def setup
    super

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

  def test_should_save_new_document_to_elasticsearch
    random_example = GovukSchemas::RandomExample
      .for_schema(notification_schema: "help_page")
      .merge_and_validate({ document_type: "help_page", payload_version: 123 })

    @queue.publish(random_example.to_json, content_type: "application/json")

    document = fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")

    assert_equal random_example["base_path"], document["_source"]["link"]
    assert_equal random_example["base_path"], document["_id"]
    assert_equal "edition", document["_type"]

    assert_equal 0, @queue.message_count
    assert_equal 1, @channel.acknowledged_state[:acked].count
  end

  def test_should_include_popularity_when_available
    random_example = GovukSchemas::RandomExample
      .for_schema(notification_schema: "help_page")
      .merge_and_validate({ document_type: "help_page", payload_version: 123 })

    # need to add additional page_traffic data in order to set maximum allowed ranking value
    4.times.each do |i|
      insert_document(
        "page-traffic_test",
        { rank_14: i },
        id: "/path/#{i}",
        type: "page-traffic"
      )
    end
    insert_document("page-traffic_test", { rank_14: 5, path_components: [random_example["base_path"]] }, id: random_example["base_path"], type: "page-traffic")
    commit_index("page-traffic_test")

    popularity = 1.0 / (5 + SearchConfig.instance.popularity_rank_offset)

    @queue.publish(random_example.to_json, content_type: "application/json")

    document = fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")

    assert_equal popularity, document["_source"]["popularity"]
  end

  def test_should_discard_message_when_invalid
    invalid_payload = {
      "title" => "Pitts S-2B, G-SKYD, 21 June 1996",
      "document_type" => "help_page"
    }

    GOVUK::Error.expects(:notify)
    @queue.publish(invalid_payload.to_json, content_type: "application/json")

    assert_equal 0, @queue.message_count
  end

  def client
    @client ||= Services::elasticsearch(hosts: SearchConfig.instance.base_uri)
  end
end
