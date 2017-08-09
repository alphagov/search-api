require 'govuk_schemas'
require 'integration_test_helper'
require 'bunny-mock'
require 'govuk_index/publishing_event_processor'
require 'govuk_message_queue_consumer'

class GovukIndex::VersioningTest < IntegrationTest
  def setup
    super

    bunny_mock = BunnyMock.new
    @channel = bunny_mock.start.channel

    consumer = GovukMessageQueueConsumer::Consumer.new(
      queue_name: "martha.test",
      processor: GovukIndex::PublishingEventProcessor.new,
      rabbitmq_connection: bunny_mock
    )

    @queue = @channel.queue("martha.test")
    consumer.run
  end

  def test_should_successfully_index_increasing_version_numbers
    random_example = GovukSchemas::RandomExample.for_schema(
      notification_schema: "specialist_document")

    version1 = random_example.merge_and_validate(payload_version: 123)
    base_path = version1["base_path"]

    @queue.publish(version1.to_json, content_type: "application/json")
    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 123, document["_version"]

    version2 = version1.merge(title: "new title", payload_version: 124)

    @queue.publish(version2.to_json, content_type: "application/json")
    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 124, document["_version"]
    assert_equal "new title", document["_source"]["title"]
  end

  def test_should_discard_message_with_same_version_as_existing_document
    random_example = GovukSchemas::RandomExample.for_schema(
      notification_schema: "specialist_document")

    version1 = random_example.merge_and_validate(payload_version: 123)
    base_path = version1["base_path"]

    @queue.publish(version1.to_json, content_type: "application/json")
    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 123, document["_version"]

    version2 = version1.merge(title: "new title", payload_version: 123)

    @queue.publish(version2.to_json, content_type: "application/json")

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 123, document["_version"]
    assert_equal version1["title"], document["_source"]["title"]
  end

  def test_should_discard_message_with_earlier_version_than_existing_document
    random_example = GovukSchemas::RandomExample.for_schema(
      notification_schema: "specialist_document")

    version1 = random_example.merge_and_validate(payload_version: 123)
    base_path = version1["base_path"]

    @queue.publish(version1.to_json, content_type: "application/json")
    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 123, document["_version"]

    version2 = version1.merge(title: "new title", payload_version: 122)

    @queue.publish(version2.to_json, content_type: "application/json")

    document = fetch_document_from_rummager(id: base_path, index: "govuk_test")
    assert_equal 123, document["_version"]
    assert_equal version1["title"], document["_source"]["title"]
  end
end
