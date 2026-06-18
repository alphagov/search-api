require "spec_helper"

RSpec.describe GovukIndex::PopularityJob do
  subject(:job) { described_class.new }
  let(:traffic_index) { SearchConfig.page_traffic_index_name }
  let(:govuk_index) { SearchConfig.govuk_index_name }
  let(:document_ids) { ["/test/page1", "/test/page2"] }

  before do
    commit_document(traffic_index,
                    { path_components: ["/test", "/test/page1"], rank_14: 2, vf_14: 0.1, vc_14: 10 },
                    id: "/test/page1")
    commit_document(traffic_index,
                    { path_components: ["/test", "/test/page2"], rank_14: 1, vf_14: 0.2, vc_14: 20 },
                    id: "/test/page2")
    allow(Sidekiq.logger).to receive(:warn)
  end

  it "saves the documents with the popularity fields values" do
    commit_document(govuk_index, build(:document, link: "/test/page1"))
    commit_document(govuk_index, build(:document, link: "/test/page2"))

    job.perform(document_ids, govuk_index)

    expect_document_is_in_rummager({ "link" => "/test/page1",
                                     "popularity" => (1.0 / 12.0),
                                     "popularity_b" => 0,
                                     "view_count" => 10 }, index: govuk_index)
    expect_document_is_in_rummager({ "link" => "/test/page2",
                                     "popularity" => (1.0 / 11.0),
                                     "popularity_b" => 1,
                                     "view_count" => 20 }, index: govuk_index)
  end

  it "writes to the logger and continues to the next document if a document is not found" do
    commit_document(govuk_index, build(:document, link: "/test/page2"))

    job.perform(document_ids, govuk_index)

    expect_document_is_in_rummager({ "link" => "/test/page2",
                                     "popularity" => (1.0 / 11.0),
                                     "popularity_b" => 1,
                                     "view_count" => 20 }, index: govuk_index)
    expect(Sidekiq.logger).to have_received(:warn).with("Skipping /test/page1 as it is not in the index")
  end
end
