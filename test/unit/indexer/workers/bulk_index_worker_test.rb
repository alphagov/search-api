require 'test_helper'

class BulkIndexWorkerTest < Minitest::Test
  SAMPLE_DOCUMENT_HASHES = %w(foo bar baz).map do |slug|
    { link: "/#{slug}", title: slug.capitalize }
  end

  def test_indexes_documents
    mock_index = mock("index")
    mock_index.expects(:bulk_index).with(SAMPLE_DOCUMENT_HASHES)
    SearchIndices::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    worker = Indexer::BulkIndexWorker.new
    worker.perform("test-index", SAMPLE_DOCUMENT_HASHES)
  end

  def test_retries_when_index_locked
    lock_delay = Indexer::BulkIndexWorker::LOCK_DELAY

    mock_index = mock("index")
    mock_index.expects(:bulk_index).raises(SearchIndices::IndexLocked)
    SearchIndices::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    Indexer::BulkIndexWorker.expects(:perform_in)
      .with(lock_delay, "test-index", SAMPLE_DOCUMENT_HASHES)

    worker = Indexer::BulkIndexWorker.new
    worker.perform("test-index", SAMPLE_DOCUMENT_HASHES)
  end

  def test_forwards_to_failure_queue
    stub_message = {}
    GovukError.expects(:notify).with(Indexer::FailedJobException.new, extra: stub_message)
    fail_block = Indexer::BulkIndexWorker.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
