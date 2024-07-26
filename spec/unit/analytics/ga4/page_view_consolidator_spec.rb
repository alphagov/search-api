require "spec_helper"
require "analytics/ga4_import/page_view_consolidator"
require "analytics/ga4_import/page_data"

RSpec.describe Analytics::Ga4Import::PageViewConsolidator do
  describe "#consolidated_page_views" do
    it "returns an empty hash when the input path is not prefixed with a slash" do
      page_data = [Analytics::Ga4Import::PageData.new("other", "other", "50")]
      page_view_consolidator = Analytics::Ga4Import::PageViewConsolidator.new(page_data)
      normalised_data = page_view_consolidator.consolidated_page_views

      expect(normalised_data).to be_empty
    end

    it "removes the trailing slash from the path" do
      page_data = [Analytics::Ga4Import::PageData.new("/example/", "example", "50")]
      page_view_consolidator = Analytics::Ga4Import::PageViewConsolidator.new(page_data)
      normalised_data = page_view_consolidator.consolidated_page_views

      expect(normalised_data).to eq({ "/example" => 50 })
    end

    it "replaces an empty string path with a slash" do
      page_data = [Analytics::Ga4Import::PageData.new("", "example", "50")]
      page_view_consolidator = Analytics::Ga4Import::PageViewConsolidator.new(page_data)
      normalised_data = page_view_consolidator.consolidated_page_views

      expect(normalised_data).to eq({ "/" => 50 })
    end

    it "returns an empty hash when the path is a smart answer" do
      page_data = [Analytics::Ga4Import::PageData.new("/other/y/other", "smart answer", "10")]
      page_view_consolidator = Analytics::Ga4Import::PageViewConsolidator.new(page_data)
      normalised_data = page_view_consolidator.consolidated_page_views

      expect(normalised_data).to be_empty
    end

    it "returns a hash with the path and page views when the path starts with a slash and it is not a smart answer" do
      page_data = [Analytics::Ga4Import::PageData.new("/example", "not a smart answer", "20")]
      page_view_consolidator = Analytics::Ga4Import::PageViewConsolidator.new(page_data)
      normalised_data = page_view_consolidator.consolidated_page_views

      expect(normalised_data).to eq({ "/example" => 20 })
    end

    it "consolidates page views for the same paths" do
      page_data = [
        Analytics::Ga4Import::PageData.new("/example", "not a smart answer", "20"),
        Analytics::Ga4Import::PageData.new("/example", "not a smart answer", "30"),
      ]
      page_view_consolidator = Analytics::Ga4Import::PageViewConsolidator.new(page_data)
      normalised_data = page_view_consolidator.consolidated_page_views

      expect(normalised_data).to eq({ "/example" => 50 })
    end

    it "consolidates page views for the same paths, ignoring query parameters" do
      page_data = [
        Analytics::Ga4Import::PageData.new("/example", "not a smart answer", "20"),
        Analytics::Ga4Import::PageData.new("/example?something=something", "not a smart answer", "30"),
      ]
      page_view_consolidator = Analytics::Ga4Import::PageViewConsolidator.new(page_data)
      normalised_data = page_view_consolidator.consolidated_page_views

      expect(normalised_data).to eq({ "/example" => 50 })
    end

    it "ignores pages with the title 'Page Not Found - 404 - GOV.UK'" do
      page_data = [
        Analytics::Ga4Import::PageData.new("/page-not-found", "Page not found - 404 - GOV.UK", "10"),
        Analytics::Ga4Import::PageData.new("/example", "not a smart answer", "20"),
      ]
      page_view_consolidator = Analytics::Ga4Import::PageViewConsolidator.new(page_data)
      normalised_data = page_view_consolidator.consolidated_page_views

      expect(normalised_data).to eq({ "/example" => 20 })
    end

    it "consolidates page views for multiple URLs" do
      page_data = [
        Analytics::Ga4Import::PageData.new("/example", "not a smart answer", "10"),
        Analytics::Ga4Import::PageData.new("/other", "other", "20"),
        Analytics::Ga4Import::PageData.new("/example?something=something", "not a smart answer", "30"),
        Analytics::Ga4Import::PageData.new("/example2", "not a smart answer", "10"),
        Analytics::Ga4Import::PageData.new("/example2?something=something", "not a smart answer", "30"),
      ]
      page_view_consolidator = Analytics::Ga4Import::PageViewConsolidator.new(page_data)
      normalised_data = page_view_consolidator.consolidated_page_views

      expect(normalised_data).to eq({ "/example" => 40, "/other" => 20, "/example2" => 40 })
    end

    it "returns the consolidated data sorted by page views in descending order" do
      page_data = [
        Analytics::Ga4Import::PageData.new("/example", "example", "20"),
        Analytics::Ga4Import::PageData.new("/example-two", "example-two", "10"),
        Analytics::Ga4Import::PageData.new("/example-three", "example-three", "30"),
        Analytics::Ga4Import::PageData.new("/example-four", "example-four", "5"),
      ]

      page_view_consolidator = Analytics::Ga4Import::PageViewConsolidator.new(page_data)

      # Converts consolidated_page_views to an array for the test as RSpec eq doesn't match based on hash order
      expect(page_view_consolidator.consolidated_page_views.to_a).to eq([["/example-three", 30], ["/example", 20], ["/example-two", 10], ["/example-four", 5]])
    end
  end
end
