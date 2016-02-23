require 'integration_test_helper'
require 'govuk_message_queue_consumer'
require 'govuk_message_queue_consumer/test_helpers'
require './lib/index_documents'

class IndexDocumentsTest < IntegrationTest
  def setup
    stub_elasticsearch_settings
    create_test_indexes
    stub_tagging_lookup
  end

  def teardown
    clean_test_indexes
  end

  def test_populated_tags_get_indexed_from_publishing_api
    commit_document('mainstream_test', link: '/my-page')

    stub_publishing_api_get_content('my-topic-id', base_path: "/topic/my-topic")
    stub_publishing_api_get_content('my-browse-page-id', base_path: "/browse/my-browse-page")
    stub_publishing_api_get_content('my-org-id', base_path: "/government/organisations/my-organisations")

    message = GovukMessageQueueConsumer::MockMessage.new({
      "base_path" => "/my-page",
      "publishing_app" => "policy-publisher",
      "links" => {
        "topics" => ["my-topic-id"],
        "mainstream_browse_pages" => ["my-browse-page-id"],
        "organisations" => ["my-org-id"],
      }
    })

    IndexDocuments.new.process(message)

    assert message.acked?
    assert_document_is_in_rummager({
      "link" => "/my-page",
      "mainstream_browse_pages" => ["my-browse-page"],
      "organisations" => ["my-organisations"],
      "specialist_sectors" => ["my-topic"],
    })
  end

  def test_skips_non_migrated_apps
    commit_document("mainstream_test", link: '/my-page')

    message = GovukMessageQueueConsumer::MockMessage.new({
      "base_path" => "/my-page",
      "publishing_app" => "unmigrated-app",
      "links" => {
        "topics" => ["my-topic-id"],
        "mainstream_browse_pages" => ["my-browse-page-id"],
        "organisations" => ["my-org-id"],
      }
    })

    IndexDocuments.new.process(message)

    assert message.acked?
    assert_document_is_in_rummager({
      "link" => "/my-page",
      "mainstream_browse_pages" => nil,
      "organisations" => nil,
      "specialist_sectors" => nil,
    })
  end

  def test_no_links_are_sent
    commit_document(
      "mainstream_test",
      link: '/my-tagged-page',
      specialist_sectors: ['my-old-topic']
    )

    message = GovukMessageQueueConsumer::MockMessage.new({
      "base_path" => "/my-tagged-page",
      "publishing_app" => "policy-publisher",
      "links" => {}
    })

    IndexDocuments.new.process(message)

    assert_document_is_in_rummager({
      "link" => "/my-tagged-page",
      "mainstream_browse_pages" => nil,
      "organisations" => nil,
      "specialist_sectors" => nil,
    })
  end

  def test_links_are_amended
    commit_document(
      "mainstream_test",
      link: '/my-tagged-page',
      specialist_sectors: ['my-old-topic']
    )

    stub_publishing_api_get_content('a-topic-uid', base_path: "/topic/a-newly-chosen-topic")

    message = GovukMessageQueueConsumer::MockMessage.new({
      "base_path" => "/my-tagged-page",
      "publishing_app" => "policy-publisher",
      "links" => {
        "topics" => ['a-topic-uid']
      }
    })

    IndexDocuments.new.process(message)

    assert_document_is_in_rummager({
      "link" => "/my-tagged-page",
      "specialist_sectors" => ['a-newly-chosen-topic'],
    })
  end

private

  def stub_publishing_api_get_content(content_id, body)
    stub_request(:get, "http://publishing-api.dev.gov.uk/v2/content/#{content_id}").
      to_return(body: body.to_json)
  end
end
