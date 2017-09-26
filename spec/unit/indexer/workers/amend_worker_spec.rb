require 'spec_helper'

RSpec.describe Indexer::AmendWorker do
  it "amends_documents" do
    mock_index = double("index")
    expect(mock_index).to receive(:amend).with("/foobang", "title" => "New title")
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with("test-index")
      .and_return(mock_index)

    worker = described_class.new
    worker.perform("test-index", "/foobang", "title" => "New title")
  end

  it "retries_when_index_locked" do
    lock_delay = Indexer::DeleteWorker::LOCK_DELAY
    mock_index = double("index")
    expect(mock_index).to receive(:amend).and_raise(SearchIndices::IndexLocked)
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with("test-index")
      .and_return(mock_index)

    expect(described_class).to receive(:perform_in)
      .with(lock_delay, "test-index", "/foobang", "title" => "New title")

    worker = described_class.new
    worker.perform("test-index", "/foobang", "title" => "New title")
  end

  it "forwards_to_failure_queue" do
    stub_message = {}
    expect(GovukError).to receive(:notify).with(Indexer::FailedJobException.new, extra: stub_message)
    fail_block = described_class.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
