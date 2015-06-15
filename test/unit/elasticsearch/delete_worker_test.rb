require "test_helper"
require "elasticsearch/base_worker"
require "elasticsearch/delete_worker"
require "elasticsearch/index"

class DeleteWorkerTest < MiniTest::Unit::TestCase
  def test_deletes_documents
    mock_index = mock("index")
    mock_index.expects(:delete).with("edition", "/foobang")
    Elasticsearch::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    worker = Elasticsearch::DeleteWorker.new
    worker.perform("test-index", "edition", "/foobang")
  end

  def test_retries_when_index_locked
    lock_delay = Elasticsearch::DeleteWorker::LOCK_DELAY
    mock_index = mock("index")
    mock_index.expects(:delete).raises(Elasticsearch::IndexLocked)
    Elasticsearch::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    Elasticsearch::DeleteWorker.expects(:perform_in)
      .with(lock_delay, "test-index", "edition", "/foobang")

    worker = Elasticsearch::DeleteWorker.new
    worker.perform("test-index", "edition", "/foobang")
  end

  def test_forwards_to_failure_queue
    stub_message = {}
    Airbrake.expects(:notify_or_ignore).with(Elasticsearch::BaseWorker::FailedJobException.new(stub_message))
    fail_block = Elasticsearch::DeleteWorker.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
