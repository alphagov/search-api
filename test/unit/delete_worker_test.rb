require "test_helper"
require "elasticsearch/delete_worker"
require "failed_job_worker"

class DeleteWorkerTest < MiniTest::Unit::TestCase
  def test_deletes_documents
    mock_index = mock("index")
    mock_index.expects(:delete).with("/foobang")
    Elasticsearch::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    worker = Elasticsearch::DeleteWorker.new
    worker.perform("test-index", "/foobang")
  end

  def test_forwards_to_failure_queue
    stub_message = {}
    FailedJobWorker.expects(:perform_async).with(stub_message)
    fail_block = Elasticsearch::DeleteWorker.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
