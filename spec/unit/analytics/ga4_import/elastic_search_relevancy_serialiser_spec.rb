require "spec_helper"

RSpec.describe Analytics::Ga4Import::ElasticSearchRelevancySerialiser do
  describe "#relevance" do
    it "returns an array of JSON object pairs of index and page data" do
      consolidated_data = [["/example", 30], ["/other", 10]]
      relevancy_data = described_class.new(consolidated_data).relevance

      index_data = JSON.parse(relevancy_data.first)
      page_data = JSON.parse(relevancy_data.second)

      expect(index_data).to match("index" => hash_including("_type" => "page-traffic", "_id" => /^\/example/))
      expect(page_data).to match(hash_including("path_components", "rank_14", "vc_14", "vf_14"))
    end

    it "specifies the page rank, views and proportion of overall views for a page" do
      consolidated_data = [["/example", 90], ["/other", 10]]
      relevancy_data = described_class.new(consolidated_data).relevance

      page_data = JSON.parse(relevancy_data.second)

      expect(page_data).to include("rank_14" => 1, "vc_14" => 90, "vf_14" => 0.9)
    end

    it "breaks up the path into an array of components for a page" do
      consolidated_data = [["/example3/child", 100]]

      relevancy_data = described_class.new(consolidated_data).relevance

      page_data = JSON.parse(relevancy_data.last)

      expect(page_data).to include("path_components" => ["/example3", "/example3/child"])
    end
  end
end
