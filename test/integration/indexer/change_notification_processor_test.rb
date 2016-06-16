require "integration_test_helper"
require "indexer/change_notification_processor"

class ChangeNotificationProcessorTest < IntegrationTest
  def setup
    stub_elasticsearch_settings
    create_test_indexes
  end

  def teardown
    clean_test_indexes
  end

  def test_triggering_a_reindex
    publishing_api_has_lookups(
      "/foo" => "DOCUMENT-CONTENT-ID"
    )

    publishing_api_has_expanded_links(
      content_id: "DOCUMENT-CONTENT-ID",
      expanded_links: {},
    )

    post "/documents", {
      'title' => 'Foo',
      'link' => '/foo',
    }.to_json

    commit_index

    assert_document_is_in_rummager({
      "link" => "/foo",
      "mainstream_browse_pages" => [],
    })

    publishing_api_has_expanded_links(
      content_id: "DOCUMENT-CONTENT-ID",
      expanded_links: {
        mainstream_browse_pages: [{
          title: "Bla",
          base_path: "/browse/my-browse"
        }]
      },
    )

    Indexer::ChangeNotificationProcessor.trigger({
      "base_path" => "/foo"
    })

    commit_index

    assert_document_is_in_rummager({
      "link" => "/foo",
      "mainstream_browse_pages" => ['my-browse'],
    })
  end
end
