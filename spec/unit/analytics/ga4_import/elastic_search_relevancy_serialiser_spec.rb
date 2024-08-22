require "spec_helper"

RSpec.describe Analytics::Ga4Import::ElasticSearchRelevancySerialiser do
  describe "#relevance" do
    it "formats relevancy JSON" do
      consolidated_data = { "/example" => 40, "/example2" => 20, "/example3" => 100, "/example3/child" => 100 }

      relevancy_calculator = described_class.new(consolidated_data)

      relevancy_data = relevancy_calculator.relevance.map { |rel| JSON.parse(rel) }

      expected = [
        { "index" => { "_id" => "/example", "_type" => "page-traffic" } },
        { "path_components" => ["/example"], "rank_14" => 1, "vc_14" => 40, "vf_14" => 0.15384615384615385 },
        { "index" => { "_id" => "/example2", "_type" => "page-traffic" } },
        { "path_components" => ["/example2"], "rank_14" => 2, "vc_14" => 20, "vf_14" => 0.07692307692307693 },
        { "index" => { "_id" => "/example3", "_type" => "page-traffic" } },
        { "path_components" => ["/example3"], "rank_14" => 3, "vc_14" => 100, "vf_14" => 0.38461538461538464 },
        { "index" => { "_id" => "/example3/child", "_type" => "page-traffic" } },
        { "path_components" => ["/example3", "/example3/child"], "rank_14" => 4, "vc_14" => 100, "vf_14" => 0.38461538461538464 },
      ]

      expect(relevancy_data).to eql(expected)
    end
  end
end
