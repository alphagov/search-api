require "spec_helper"

RSpec.describe Analytics::Ga4Import::PageViewConsolidator do
  let(:really_long_path) { "/#{'a'.b * (Analytics::Ga4Import::PageViewConsolidator::MAX_PATH_LENGTH - 1)}" }

  let(:ga_data) do
    [
      Analytics::Ga4Import::PageData.new("/example1", "Title", 10),
      Analytics::Ga4Import::PageData.new("/example2", "Title ", 100),
      Analytics::Ga4Import::PageData.new("/example2", "Title", 10),
      Analytics::Ga4Import::PageData.new("/example3", "Title", 10),
      Analytics::Ga4Import::PageData.new("/example3/blah", "Title", 10),
      Analytics::Ga4Import::PageData.new("/example4/blah?query_params", "Title", 60),
      Analytics::Ga4Import::PageData.new("/example4/blah", "Title", 40),
      Analytics::Ga4Import::PageData.new("/example3/y/blah", "Smart Answer", 1000),
      Analytics::Ga4Import::PageData.new("http://example.com/example99", "Title", 10),
      Analytics::Ga4Import::PageData.new("/not-real-path", "Page not found - GOV.UK", 99),
      Analytics::Ga4Import::PageData.new(really_long_path, "Path is too long", 10),
    ]
  end

  subject(:consolidator) { described_class.new(ga_data) }

  describe "#consolidated_page_views" do
    it "outputs a list of page views and paths" do
      expect(consolidator.consolidated_page_views).to all(include(a_kind_of(String), a_kind_of(Integer)))
      expect(consolidator.consolidated_page_views.count).to eq(5)
    end

    it "orders the list by page views" do
      page_views = consolidator.consolidated_page_views.map(&:last)
      expect(page_views).to eq(page_views.sort.reverse)
    end

    it "doesn't include page data that is excluded" do
      expect(consolidator.consolidated_page_views).not_to include(["/example3/y/blah", 1000])
      expect(consolidator.consolidated_page_views).not_to include(["/not-real-path", 99])
      expect(consolidator.consolidated_page_views).not_to include(["http://example.com/example99", 10])
    end

    it "combines page views for the same path" do
      expect(consolidator.consolidated_page_views).to include(["/example2", 110])
    end

    it "combines page views for page data that normalises to the same path" do
      expect(consolidator.consolidated_page_views).to include(["/example4/blah", 100])
    end

    it "removes paths longer than MAX_PATH_LENGTH bytes" do
      expect(consolidator.consolidated_page_views).not_to include([really_long_path, 10])
    end
  end
end
