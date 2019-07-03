require 'spec_helper'
require 'sidekiq/testing'

RSpec.describe Indexer::AmendWorker do
  let(:index_name) {'government_test'}
  let(:link) {'/doc-for-deletion'}
  let(:content_id) {'41609206-8736-4ff3-b582-63c9fccafe4d'}
  let(:document) {{"title" => 'Old title', "content_id" => content_id, "link" => link}}
  let(:updates) {{"title" => "New title"}}

  before(:each) do
    Sidekiq::Worker.clear_all
  end

  it "amends documents" do
    Sidekiq::Testing.fake! do
      commit_document(index_name, document)

      request = stub_request_to_publishing_api(content_id)

      described_class.new.perform(index_name, link, updates)

      doc_with_updates = document.merge(updates)

      # Previously, this used a let to store Clusters.count, however,
      # I _think_ that this meant that if the test that only used one cluster ran before
      # this one, then the incorrect cluster count was stored, the request was made twice
      # but it asserted that there should only be one request, which is wrong
      assert_requested request, times: Clusters.count
      expect_document_is_in_rummager(doc_with_updates, id: link, index: index_name)
    end
  end

  it "retries when index locked" do
    Sidekiq::Testing.fake! do
      with_just_one_cluster
      lock_delay = Indexer::DeleteWorker::LOCK_DELAY
      mock_index = double("index") # rubocop:disable RSpec/VerifiedDoubles
      # rubocop:disable RSpec/MessageSpies

      # We can change these to allow (IMHO) becausee don't really care how many times they were called, that's
      # an implementation detail, we only care that the job count was increased
      allow(mock_index).to receive(:amend).and_raise(SearchIndices::IndexLocked)
      allow_any_instance_of(SearchIndices::SearchServer).to receive(:index) # rubocop:disable RSpec/AnyInstance
                                                               .with(index_name)
                                                               .and_return(mock_index)

      # rubocop:enable RSpec/MessageSpies
      worker = described_class.new
      expect {
        worker.perform(index_name, link, updates)
      }.to change {Indexer::AmendWorker.jobs.count}.by(1)
    end
  end

  it "forwards to failure queue" do
    stub_message = {}
    # rubocop:disable RSpec/MessageSpies
    expect(GovukError).to receive(:notify).with(Indexer::FailedJobException.new, extra: stub_message)
    # rubocop:enable RSpec/MessageSpies
    fail_block = described_class.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end

  def stub_request_to_publishing_api(id)
    endpoint = Plek.current.find('publishing-api') + '/v2'
    expanded_links_url = endpoint + "/expanded-links/" + id

    stub_request(:get, expanded_links_url).to_return(status: 200, body: {}.to_json)
  end
end
