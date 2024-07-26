require "spec_helper"
require "analytics/ga4_import/page_data"

RSpec.describe Analytics::Ga4Import::PageData do
  subject(:page_data) { described_class.new(path, title, page_views) }

  let(:path) { "/test/path" }
  let(:title) { "Test Title" }
  let(:page_views) { "100" }

  describe "#excluded?" do
    context "when the path is non-relative" do
      let(:path) { "http://example.com/test/path" }

      it "returns true" do
        expect(page_data.excluded?).to be true
      end
    end

    context "when the path is a smart answer" do
      let(:path) { "/test/path/y/answer" }

      it "returns true" do
        expect(page_data.excluded?).to be true
      end
    end

    context "when the title is 'Page not found'" do
      let(:title) { "Page not found" }

      it "returns true" do
        expect(page_data.excluded?).to be true
      end
    end

    context "when the path is relative, not a smart answer, and the title is not 'Page not found'" do
      it "returns false" do
        expect(page_data.excluded?).to be false
      end
    end
  end

  describe "#normalised_path" do
    context "when the path has a query string" do
      let(:path) { "/test/path?query=string" }

      it "returns the path without the query string" do
        expect(page_data.normalised_path).to eq("/test/path")
      end
    end

    context "when the path ends with a slash" do
      let(:path) { "/test/path/" }

      it "returns the path without the trailing slash" do
        expect(page_data.normalised_path).to eq("/test/path")
      end
    end

    context "when the path is just a slash" do
      let(:path) { "/" }

      it "returns '/'" do
        expect(page_data.normalised_path).to eq("/")
      end
    end
  end
end
