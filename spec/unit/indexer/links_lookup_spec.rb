require "spec_helper"

RSpec.describe Indexer::LinksLookup do
  include GdsApi::TestHelpers::PublishingApi

  let(:content_id) { "DOCUMENT_CONTENT_ID" }
  let(:endpoint) { Plek.current.find("publishing-api") + "/v2" }
  let(:expanded_links_url) { endpoint + "/expanded-links/" + content_id }

  it "retry links on timeout" do
    stub_request(:get, expanded_links_url).to_timeout

    expect {
      described_class.prepare_tags({
        "content_id" => content_id,
        "link" => "/my-base-path",
      })
    }.to raise_error(Indexer::PublishingApiError)

    assert_requested :get, expanded_links_url, times: 5
  end

  it "doesn't error if content no longer exists" do
    stub_request(:get, expanded_links_url).to_return(body: "Not found", status: 404)

    expanded_content = described_class.prepare_tags({
      "content_id" => content_id,
      "link" => "/my-base-path",
    })

    expect(expanded_content).to eq("content_id" => content_id, "link" => "/my-base-path")
  end
end
