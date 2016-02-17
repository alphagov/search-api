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

  def test_populated_tags_get_indexed_from_publishing_api
    Elasticsearch::Amender.any_instance.expects(:amend)
      .with('/topic/animal-welfare/pets', {
              "mainstream_browse_pages" => ['/path/2'],
              "organisations" => ['/path/3'],
              "specialist_sectors" => ['/path/1'],
            })

    m = GovukMessageQueueConsumer::MockMessage.new(payload_with_tags)
    IndexDocuments.new.process(m)

    assert m.acked?
  end

  def test_empty_tags_get_indexed_from_publishing_api
    Elasticsearch::Amender.any_instance.expects(:amend)
      .with('/topic/animal-welfare/pets', {
              "mainstream_browse_pages" => [],
              "organisations" => [],
              "specialist_sectors" => [],
            })

    m = GovukMessageQueueConsumer::MockMessage.new(payload_empty_tags)
    IndexDocuments.new.process(m)

    assert m.acked?
  end

  def test_no_tags_no_update
    Elasticsearch::Amender.any_instance.expects(:amend).never

    m = GovukMessageQueueConsumer::MockMessage.new(payload_no_tags)
    IndexDocuments.new.process(m)

    assert m.acked?
  end

  def test_no_links_no_update
    Elasticsearch::Amender.any_instance.expects(:amend).never

    m = GovukMessageQueueConsumer::MockMessage.new(payload_no_links)
    IndexDocuments.new.process(m)

    assert m.acked?
  end

  def test_migrated_publishing_app_sorts_links
    Elasticsearch::Amender.any_instance.expects(:amend)
      .with('/topic/animal-welfare/pets', {
              "mainstream_browse_pages" => [],
              "organisations" => [],
              "specialist_sectors" => sorted_links,
            })
    m = GovukMessageQueueConsumer::MockMessage.new(payload_migrated_publishing_app)
    IndexDocuments.new.process(m)
  end

  def test_non_migrated_publishing_app_no_update
    Elasticsearch::Amender.any_instance.expects(:amend).never

    m = GovukMessageQueueConsumer::MockMessage.new(payload_non_migrated_publishing_app)
    IndexDocuments.new.process(m)

    assert m.acked?
  end

  def sorted_links
    ['/path/1', '/path/2', '/path/3']
  end


  def payload_non_migrated_publishing_app
    payload_no_tags.merge({
                            "publishing_app" => "other-app",
                          })
  end

  def payload_migrated_publishing_app
    payload_with_tags.merge({
                              "links" => {
                                "topics" => ["uuid-3", "uuid-2", "uuid-1"],
                              }
                            })
  end

  def payload_with_tags
    payload_empty_tags.merge({ "links" => {
                                   "topics" => ["uuid-1"],
                                   "mainstream_browse_pages" => ["uuid-2"],
                                   "organisations" => ["uuid-3"],
                                 } })
  end

  def payload_empty_tags
    payload_no_tags.merge({ "links" => {
                                "topics" => [],
                                "mainstream_browse_page" => [],
                                "organisations" => [],
                              } })
  end

  def payload_no_tags
    payload_no_links.merge({ "links" => {} })
  end

  def payload_no_links
    {
      "base_path" => "/topic/animal-welfare/pets",
      "publishing_app" => "policy-publisher",
    }
  end
end
