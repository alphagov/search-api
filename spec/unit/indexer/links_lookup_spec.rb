require 'spec_helper'

RSpec.describe Indexer::LinksLookup do
  include GdsApi::TestHelpers::PublishingApiV2

  it "retry_links_on_timeout" do
    content_id = "DOCUMENT_CONTENT_ID"
    endpoint = Plek.current.find('publishing-api') + '/v2'
    expanded_links_url = endpoint + "/expanded-links/" + content_id
    stub_request(:get, expanded_links_url).to_timeout

    assert_raises(Indexer::PublishingApiError) do
      described_class.prepare_tags({
        "content_id" => content_id,
        "link" => "/my-base-path",
      })
    end

    assert_requested :get, expanded_links_url, times: 5
  end
end
