require 'spec_helper'

RSpec.describe 'AmendWorkerTest' do
  it "amends_documents" do
    mock_index = mock("index")
    mock_index.expects(:amend).with("/foobang", "title" => "New title")
    SearchIndices::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    worker = Indexer::AmendWorker.new
    worker.perform("test-index", "/foobang", "title" => "New title")
  end

  it "retries_when_index_locked" do
    lock_delay = Indexer::DeleteWorker::LOCK_DELAY
    mock_index = mock("index")
    mock_index.expects(:amend).raises(SearchIndices::IndexLocked)
    SearchIndices::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    Indexer::AmendWorker.expects(:perform_in)
      .with(lock_delay, "test-index", "/foobang", "title" => "New title")

    worker = Indexer::AmendWorker.new
    worker.perform("test-index", "/foobang", "title" => "New title")
  end

  it "forwards_to_failure_queue" do
    stub_message = {}
    GovukError.expects(:notify).with(Indexer::FailedJobException.new, extra: stub_message)
    fail_block = Indexer::AmendWorker.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
