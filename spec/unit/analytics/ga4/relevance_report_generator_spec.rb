require "spec_helper"
require "analytics/ga4_import/relevance_report_generator"

RSpec.describe Analytics::Ga4Import::RelevanceReportGenerator do
  describe ".call" do
    subject(:call) { described_class.call }

    let(:data_fetcher) { instance_double(Analytics::Ga4Import::DataFetcher, call: "paginated_data") }
    let(:page_view_consolidator) { instance_double(Analytics::Ga4Import::PageViewConsolidator, consolidated_page_views: "consolidated_page_views") }
    let(:relevancy_calculator) { instance_double(Analytics::Ga4Import::ElasticSearchRelevancySerialiser, relevance: "relevance") }

    before do
      allow(Analytics::Ga4Import::DataFetcher).to receive(:new).and_return(data_fetcher)
      allow(Analytics::Ga4Import::PageViewConsolidator).to receive(:new).with("paginated_data").and_return(page_view_consolidator)
      allow(Analytics::Ga4Import::ElasticSearchRelevancySerialiser).to receive(:new).with("consolidated_page_views").and_return(relevancy_calculator)
    end

    it "returns the relevancy as a string" do
      expect(call).to eq("relevance")
    end
  end
end
