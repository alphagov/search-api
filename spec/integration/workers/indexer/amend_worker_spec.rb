require "spec_helper"
require "sidekiq/testing"

RSpec.describe Indexer::AmendWorker do
  let(:index_name) { "government_test" }
  let(:link) { "/doc-for-deletion" }
  let(:content_id) { "41609206-8736-4ff3-b582-63c9fccafe4d" }
  let(:document) { { "title" => "Old title", "content_id" => content_id, "link" => link } }
  let(:updates) { { "title" => "New title" } }
  let(:cluster_count) { Clusters.count }

  before do
    Sidekiq::Worker.clear_all
  end

  it "amends documents" do
    commit_document(index_name, document)

    request = stub_request_to_publishing_api(content_id)

    described_class.new.perform(index_name, link, updates)

    doc_with_updates = document.merge(updates)

    assert_requested request, times: cluster_count
    expect_document_is_in_rummager(doc_with_updates, id: link, index: index_name)
  end

  it "retries when index locked" do
    Sidekiq::Testing.fake! do
      with_just_one_cluster
      mock_index = double("index")
      expect(mock_index).to receive(:amend).and_raise(SearchIndices::IndexLocked)

      expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
                                                               .with(index_name)
                                                               .and_return(mock_index)

      worker = described_class.new
      expect {
        worker.perform(index_name, link, updates)
      }.to change { described_class.jobs.count }.by(1)
    end
  end

  it "forwards to failure queue" do
    stub_message = {}
    expect(GovukError).to receive(:notify).with(Indexer::FailedJobException.new, extra: stub_message)

    fail_block = described_class.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end

  def stub_request_to_publishing_api(id)
    endpoint = Plek.current.find("publishing-api") + "/v2"
    expanded_links_url = endpoint + "/expanded-links/" + id

    stub_request(:get, expanded_links_url).to_return(status: 200, body: {}.to_json)
  end
end
