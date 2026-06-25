require "spec_helper"
require "rake"

RSpec.describe "page_traffic" do
  before do
    task.reenable
    allow(::Google::Analytics::Data::V1beta::AnalyticsData::Client).to receive(:new).and_return(ga_client)
  end

  describe "page_traffic:load", type: :task do
    let(:task_name) { "page_traffic:load" }
    let(:task) { Rake::Task[task_name] }
    let(:index) { SearchConfig.page_traffic_index_name }
    let(:ga_client) { double(::Google::Analytics::Data::V1beta::AnalyticsData::Client) }
    let(:report) do
      { rows:
        [{ dimension_values: [{ value: "/doc1" }, { value: "doc 1" }],
           metric_values: [{ value: "100" }] },
         { dimension_values: [{ value: "/doc2" }, { value: "doc 2" }],
           metric_values: [{ value: "200" }] }] }
    end
    before do
      allow(ga_client).to receive(:run_report).and_return(report, {})
    end
    it "Adds entries to the traffic index" do
      task.invoke

      document1 = fetch_document_from_rummager(id: "/doc1", index:)
      document2 = fetch_document_from_rummager(id: "/doc2", index:)

      expect(document1["_source"]).to include("rank_14" => 2, "vc_14" => 100, "vf_14" => 100.0 / 300.0)
      expect(document2["_source"]).to include("rank_14" => 1, "vc_14" => 200, "vf_14" => 200.0 / 300.0)
    end
  end
end
