require "test_helper"
require "indexer/links_lookup"

describe Indexer::LinksLookup do
  describe "#rummager_fields_from_links" do
    it "returns transformed links" do
      stub_request(:get, "http://publishing-api.dev.gov.uk/v2/content/MSBP-CONTENT-ID").
        to_return(body: { base_path: "/browse/working/time-off" }.to_json)

      stub_request(:get, "http://publishing-api.dev.gov.uk/v2/content/ORG-CONTENT-ID").
        to_return(body: { base_path: "/government/organisations/accelerated-access-review" }.to_json)

      stub_request(:get, "http://publishing-api.dev.gov.uk/v2/content/TOPIC-CONTENT-ID").
        to_return(body: { base_path: "/topic/schools-colleges-childrens-services/adoption-fostering" }.to_json)

      rummager_links = rummager_links_for({
        "topics" => ["TOPIC-CONTENT-ID"],
        "mainstream_browse_pages" => ["MSBP-CONTENT-ID"],
        "organisations" => ["ORG-CONTENT-ID"]
      })

      assert_equal rummager_links, {
        "mainstream_browse_pages" => ["working/time-off"],
        "organisations" => ["accelerated-access-review"],
        "specialist_sectors" => ["schools-colleges-childrens-services/adoption-fostering"]
      }
    end

    it "returns transformed links when non-existing items are linked" do
      stub_request(:get, "http://publishing-api.dev.gov.uk/v2/content/4da67807").
        to_return(status: 404, body: {}.to_json)

      rummager_links = rummager_links_for({
        "topics" => ["4da67807"]
      })

      assert_equal rummager_links, {
        "mainstream_browse_pages" => [],
        "organisations" => [],
        "specialist_sectors" => []
      }
    end

    def rummager_links_for(links)
      Indexer::LinksLookup.new.rummager_fields_from_links(links)
    end
  end
end
