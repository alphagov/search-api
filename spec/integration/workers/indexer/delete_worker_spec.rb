require "spec_helper"

RSpec.describe Indexer::DeleteWorker do
  let(:index_name) { "government_test" }
  let(:link) { "doc-for-deletion" }
  let(:document_type) { "generic-document" }
  let(:document) do
    {
      "content_id" => "41609206-8736-4ff3-b582-63c9fccafe4d",
      "link" => link,
    }
  end

  it "deletes documents" do
    commit_document(index_name, document)
    expect_document_is_in_rummager(document, id: link, index: index_name)

    worker = described_class.new
    worker.perform(index_name, document_type, link)

    expect_document_missing_in_rummager(id: link, index: index_name)
  end

  it "retries when index locked" do
    with_just_one_cluster
    lock_delay = described_class::LOCK_DELAY
    mock_index = double(SearchIndices::Index)
    expect(mock_index).to receive(:delete).and_raise(SearchIndices::IndexLocked)
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with("test-index")
      .and_return(mock_index)
    expect(described_class).to receive(:perform_in)
      .with(lock_delay, "test-index", "edition", "/foobang")

    worker = described_class.new
    worker.perform("test-index", "edition", "/foobang")
  end

  it "forwards to failure queue" do
    stub_message = {}
    expect(GovukError).to receive(:notify).with(Indexer::FailedJobException.new, extra: stub_message)

    fail_block = described_class.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
