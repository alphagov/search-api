require "test_helper"
require "indexer/links_lookup"
require "gds_api/test_helpers/publishing_api_v2"

class LinksLookupTest < MiniTest::Unit::TestCase
  include GdsApi::TestHelpers::PublishingApiV2

  def test_retry_links_on_timeout
    content_id = "DOCUMENT_CONTENT_ID"
    endpoint = Plek.current.find('publishing-api') + '/v2'
    expanded_links_url = endpoint + "/expanded-links/" + content_id
    stub_request(:get, expanded_links_url).to_timeout

    assert_raises(Indexer::PublishingApiError) do
      Indexer::LinksLookup.prepare_tags({
        "content_id" => content_id,
        "link" => "/my-base-path",
      })
    end

    assert_requested :get, expanded_links_url, times: 5
  end
end
