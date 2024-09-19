require "spec_helper"

RSpec.describe Analytics::Ga4Import::RelevanceReportGenerator do
  let(:data_fetcher) { instance_double(Analytics::Ga4Import::DataFetcher) }
  let(:page_view_consolidator) { instance_double(Analytics::Ga4Import::PageViewConsolidator) }
  let(:relevancy_calculator) { instance_double(Analytics::Ga4Import::ElasticSearchRelevancySerialiser) }

  before do
    allow(Analytics::Ga4Import::DataFetcher).to receive(:new).and_return(data_fetcher)
    allow(data_fetcher).to receive(:call).and_return(:paginated_data)

    allow(Analytics::Ga4Import::PageViewConsolidator).to receive(:new).and_return(page_view_consolidator)
    allow(page_view_consolidator).to receive(:consolidated_page_views).and_return(:consolidated_page_views)

    allow(Analytics::Ga4Import::ElasticSearchRelevancySerialiser).to receive(:new).and_return(relevancy_calculator)
    allow(relevancy_calculator).to receive(:relevance).and_return(['{"index": {"_index": "page-traffic", "_id": 1}}', '{"path": "/a/b/c", "views": 100}'])
  end

  it "calls DataFetcher, PageViewConsolidator, and ElasticSearchRelevancySerialiser" do
    result = described_class.new.call

    expect(Analytics::Ga4Import::DataFetcher).to have_received(:new)
    expect(data_fetcher).to have_received(:call)

    expect(Analytics::Ga4Import::PageViewConsolidator).to have_received(:new).with(:paginated_data)
    expect(page_view_consolidator).to have_received(:consolidated_page_views)

    expect(Analytics::Ga4Import::ElasticSearchRelevancySerialiser).to have_received(:new).with(:consolidated_page_views)
    expect(relevancy_calculator).to have_received(:relevance)

    expect(result).to be_kind_of(String)
    result.split("\n").each do |line|
      expect { JSON.parse(line) }.not_to raise_error
    end
  end
end
