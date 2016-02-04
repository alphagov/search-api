require "integration_test_helper"
require 'govuk_message_queue_consumer'
require 'govuk_message_queue_consumer/test_helpers'
require './lib/index_documents'

class IndexDocumentsTest < IntegrationTest
  include IndexDocumentsTestHelpers

  def setup
    stub_elasticsearch_settings
    create_test_indexes
    stub_tagging_lookup
    stub_calls_for_index_documents_test
  end

  def teardown
    clean_test_indexes
  end

  def test_topics_get_indexed_from_publishing_api
    Elasticsearch::Amender.any_instance.expects(:amend)

    m = GovukMessageQueueConsumer::MockMessage.new(payload_with_topics)
    IndexDocuments.new.process(m)

    assert m.acked?
  end

  def test_empty_topics_get_indexed_from_publishing_api
    Elasticsearch::Amender.any_instance.expects(:amend)

    m = GovukMessageQueueConsumer::MockMessage.new(payload_empty_topics)
    IndexDocuments.new.process(m)

    assert m.acked?
  end

  def test_no_topics_no_update
    Elasticsearch::Amender.any_instance.expects(:amend).never

    m = GovukMessageQueueConsumer::MockMessage.new(payload_no_topics)
    IndexDocuments.new.process(m)

    assert m.acked?
  end

  def test_no_links_no_update
    Elasticsearch::Amender.any_instance.expects(:amend).never

    m = GovukMessageQueueConsumer::MockMessage.new(payload_no_links)
    IndexDocuments.new.process(m)

    assert m.acked?
  end

  def payload_with_topics
    payload_empty_topics.merge({"links" => {"topics" => ["cc9eb8ab-7701-43a7-a66d-bdc5046224c0"]}})
  end

  def payload_empty_topics
    payload_no_topics.merge({"links" => {"topics" => []}})
  end

  def payload_no_topics
    payload_no_links.merge({"links" => {}})
  end

  def payload_no_links
    { "base_path" => "/topic/animal-welfare/pets" }
  end
end
