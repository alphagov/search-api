require "test_helper"
require "indexer/links_lookup"

describe Indexer::LinksLookup do
  describe "#rummager_fields_from_links" do
    it "returns transformed links" do
      stub_request(:get, "http://publishing-api.dev.gov.uk/v2/content/b6b7d71f-ecf3-4ff0-8fee-f19041cbe6b5").
        to_return(body: { base_path: "/hela" }.to_json)

      rummager_links = rummager_links_for({
        "topics" => ["b6b7d71f-ecf3-4ff0-8fee-f19041cbe6b5"]
      })

      assert_equal rummager_links, {
        "mainstream_browse_pages" => [],
        "organisations"=>[],
        "specialist_sectors" => ["/hela"]
      }
    end

    def rummager_links_for(links)
      Indexer::LinksLookup.new.rummager_fields_from_links(links)
    end
  end
end
