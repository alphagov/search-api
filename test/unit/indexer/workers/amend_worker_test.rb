require "test_helper"
require "indexer/workers/amend_worker"
require "indexer/workers/base_worker"
require "index"

class AmendWorkerTest < MiniTest::Unit::TestCase
  def test_amends_documents
    mock_index = mock("index")
    mock_index.expects(:amend).with("/foobang", "title" => "New title")
    SearchIndices::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    worker = Indexer::AmendWorker.new
    worker.perform("test-index", "/foobang", "title" => "New title")
  end

  def test_retries_when_index_locked
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

  def test_forwards_to_failure_queue
    stub_message = {}
    Airbrake.expects(:notify_or_ignore).with(Indexer::FailedJobException.new, parameters: stub_message)
    fail_block = Indexer::AmendWorker.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
