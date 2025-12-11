require "spec_helper"

RSpec.describe GovukIndex::SupertypeUpdater do
  describe ".update" do
    let(:supertype_job) { double(GovukIndex::SupertypeJob) }
    let(:scroll_enumerator) { instance_double(ScrollEnumerator) }

    before do
      allow(GovukIndex::SupertypeJob).to receive(:perform_async).and_return(true)
    end

    it "calls the SupertypeJob for all documents in the index" do
      data = { "_id" => "abc", "_type" => "generic-document", "_source" => { "custom" => "data", "document_type" => "stuff" } }
      stub_client_for_scroll_enumerator(return_values: [[data], []])

      described_class.update("govuk_test")

      expect(GovukIndex::SupertypeJob).to have_received(:perform_async).with(%w[abc], "govuk_test")
    end
  end

  def stub_client_for_scroll_enumerator(return_values:, search_body: nil, search_type: "query_then_fetch")
    client = double(:client)
    allow(Services).to receive(:elasticsearch).and_return(client)

    expect(client).to receive(:search).with(
      hash_including(
        index: "govuk_test",
        search_type:,
        body: search_body || {
          query: { match_all: {} },
          sort: %w[_doc],
        },
      ),
    ).and_return(
      { "_scroll_id" => "scroll_ID_0", "hits" => { "total" => 1, "hits" => return_values[0] } },
    )

    return_values[1..].each_with_index do |return_value, i|
      expect(client).to receive(:scroll).with(
        scroll_id: "scroll_ID_#{i}", scroll: "1m",
      ).and_return(
        { "_scroll_id" => "scroll_ID_#{i + 1}", "hits" => { "hits" => return_value } },
      )
    end
  end
end
