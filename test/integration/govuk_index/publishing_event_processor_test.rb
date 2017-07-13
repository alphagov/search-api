require 'govuk_schemas'
require 'integration_test_helper'
require 'bunny-mock'
require 'govuk_index/publishing_event_processor'
require 'govuk_message_queue_consumer'

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
    schema = GovukSchemas::Schema.find(frontend_schema: "specialist_document")
    random_example = GovukSchemas::RandomExample.new(schema: schema).payload

    @queue.publish(random_example.to_json, content_type: "application/json")

    document = fetch_document_from_rummager(id: random_example["base_path"], index: "govuk_test")

    assert_equal random_example["base_path"], document["_source"]["link"]
    assert_equal random_example["base_path"], document["_id"]
    assert_equal random_example["document_type"], document["_type"]

    assert_equal 0, @queue.message_count
    assert_equal 1, @channel.acknowledged_state[:acked].count
  end

  def test_should_discard_message_when_invalid
    invalid_payload = {
      "title" => "Pitts S-2B, G-SKYD, 21 June 1996",
      "document_type" => "aaib_report"
    }

    Airbrake.expects(:notify_or_ignore).with(instance_of(GovukIndex::ValidationError))
    @queue.publish(invalid_payload.to_json, content_type: "application/json")

    assert_equal 0, @queue.message_count
  end

  def client
    @client ||= Services::elasticsearch(hosts: Rummager.search_config.base_uri)
  end
end
