require 'test_helper'

class DeleteWorkerTest < Minitest::Test
  def test_deletes_documents
    mock_index = mock("index")
    mock_index.expects(:delete).with("edition", "/foobang")
    SearchIndices::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    worker = Indexer::DeleteWorker.new
    worker.perform("test-index", "edition", "/foobang")
  end

  def test_retries_when_index_locked
    lock_delay = Indexer::DeleteWorker::LOCK_DELAY
    mock_index = mock("index")
    mock_index.expects(:delete).raises(SearchIndices::IndexLocked)
    SearchIndices::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    Indexer::DeleteWorker.expects(:perform_in)
      .with(lock_delay, "test-index", "edition", "/foobang")

    worker = Indexer::DeleteWorker.new
    worker.perform("test-index", "edition", "/foobang")
  end

  def test_forwards_to_failure_queue
    stub_message = {}
    GOVUK::Error.expects(:notify).with(Indexer::FailedJobException.new, parameters: stub_message)
    fail_block = Indexer::DeleteWorker.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
