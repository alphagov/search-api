require "test_helper"
require "elasticsearch/amend_worker"
require "elasticsearch/base_worker"
require "elasticsearch/index"

class AmendWorkerTest < MiniTest::Unit::TestCase
  def test_amends_documents
    mock_index = mock("index")
    mock_index.expects(:amend).with("/foobang", "title" => "New title")
    Elasticsearch::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    worker = Elasticsearch::AmendWorker.new
    worker.perform("test-index", "/foobang", "title" => "New title")
  end

  def test_retries_when_index_locked
    lock_delay = Elasticsearch::DeleteWorker::LOCK_DELAY
    mock_index = mock("index")
    mock_index.expects(:amend).raises(Elasticsearch::IndexLocked)
    Elasticsearch::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    Elasticsearch::AmendWorker.expects(:perform_in)
      .with(lock_delay, "test-index", "/foobang", "title" => "New title")

    worker = Elasticsearch::AmendWorker.new
    worker.perform("test-index", "/foobang", "title" => "New title")
  end

  def test_forwards_to_failure_queue
    stub_message = {}
    Airbrake.expects(:notify_or_ignore).with(Elasticsearch::BaseWorker::FailedJobException.new(stub_message))
    fail_block = Elasticsearch::AmendWorker.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
