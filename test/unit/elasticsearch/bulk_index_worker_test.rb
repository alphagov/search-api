require "test_helper"
require "elasticsearch/base_worker"
require "elasticsearch/bulk_index_worker"
require "elasticsearch/index"

class BulkIndexWorkerTest < MiniTest::Unit::TestCase
  SAMPLE_DOCUMENT_HASHES = %w(foo bar baz).map do |slug|
    { link: "/#{slug}", title: slug.capitalize }
  end

  def test_indexes_documents
    mock_index = mock("index")
    mock_index.expects(:bulk_index).with(SAMPLE_DOCUMENT_HASHES)
    Elasticsearch::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    worker = Elasticsearch::BulkIndexWorker.new
    worker.perform("test-index", SAMPLE_DOCUMENT_HASHES)
  end

  def test_retries_when_index_locked
    lock_delay = Elasticsearch::BulkIndexWorker::LOCK_DELAY

    mock_index = mock("index")
    mock_index.expects(:bulk_index).raises(Elasticsearch::IndexLocked)
    Elasticsearch::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    Elasticsearch::BulkIndexWorker.expects(:perform_in)
      .with(lock_delay, "test-index", SAMPLE_DOCUMENT_HASHES)

    worker = Elasticsearch::BulkIndexWorker.new
    worker.perform("test-index", SAMPLE_DOCUMENT_HASHES)
  end

  def test_forwards_to_failure_queue
    stub_message = {}
    Airbrake.expects(:notify_or_ignore).with(Elasticsearch::BaseWorker::FailedJobException.new(stub_message))
    fail_block = Elasticsearch::BulkIndexWorker.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
