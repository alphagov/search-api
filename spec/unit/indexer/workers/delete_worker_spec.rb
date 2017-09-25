require 'spec_helper'

RSpec.describe 'DeleteWorkerTest' do
  it "deletes_documents" do
    mock_index = double("index")
    expect(mock_index).to receive(:delete).with("edition", "/foobang")
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with("test-index")
      .and_return(mock_index)

    worker = Indexer::DeleteWorker.new
    worker.perform("test-index", "edition", "/foobang")
  end

  it "retries_when_index_locked" do
    lock_delay = Indexer::DeleteWorker::LOCK_DELAY
    mock_index = double("index")
    expect(mock_index).to receive(:delete).and_raise(SearchIndices::IndexLocked)
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with("test-index")
      .and_return(mock_index)

    expect(Indexer::DeleteWorker).to receive(:perform_in)
      .with(lock_delay, "test-index", "edition", "/foobang")

    worker = Indexer::DeleteWorker.new
    worker.perform("test-index", "edition", "/foobang")
  end

  it "forwards_to_failure_queue" do
    stub_message = {}
    expect(GovukError).to receive(:notify).with(Indexer::FailedJobException.new, extra: stub_message)
    fail_block = Indexer::DeleteWorker.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
