require "spec_helper"
require "analytics/transform"
require "analytics/extract"

RSpec.describe Analytics::Transform do
  subject(:transformer) { described_class }

  describe "#to_csv" do
    let(:extracted_data) do
      instance_double(
        "Analytics::Extract",
        rows: [[
          "587b0635-2911-49e6-af68-3f0ea1b07cc5",
          "/an-example-page",
          "some_publishing_org",
          nil,
          "some page title",
          "some_document_type",
          "some_navigation_supertype",
          nil,
          "some_user_journey_supertype",
          "some_org, another_org, yet_another_org",
          "20170620",
          nil,
          nil,
        ]],
        headers: [
          "ga:productSku",
          "ga:productName",
          "ga:productBrand",
          "ga:productCategoryHierarchy",
          "ga:dimension72",
          "ga:dimension73",
          "ga:dimension74",
          "ga:dimension75",
          "ga:dimension76",
          "ga:dimension77",
          "ga:dimension78",
          "ga:dimension79",
          "ga:dimension80",
          "ga:productSku",
        ],
      )
    end

    it "converts an Analytics::Extract to a CSV format" do
      expected = <<~CSV
        ga:productSku,ga:productName,ga:productBrand,ga:productCategoryHierarchy,ga:dimension72,ga:dimension73,ga:dimension74,ga:dimension75,ga:dimension76,ga:dimension77,ga:dimension78,ga:dimension79,ga:dimension80,ga:productSku
        587b0635-2911-49e6-af68-3f0ea1b07cc5,/an-example-page,some_publishing_org,,some page title,some_document_type,some_navigation_supertype,,some_user_journey_supertype,"some_org, another_org, yet_another_org",20170620,,
      CSV
      expect(transformer.to_csv(extracted_data)).to eq(expected)
    end
  end
end
