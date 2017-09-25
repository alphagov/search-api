require 'spec_helper'

RSpec.describe 'BulkIndexWorkerTest' do
  SAMPLE_DOCUMENT_HASHES = %w(foo bar baz).map do |slug|
    { link: "/#{slug}", title: slug.capitalize }
  end

  it "indexes_documents" do
    mock_index = mock("index")
    mock_index.expects(:bulk_index).with(SAMPLE_DOCUMENT_HASHES)
    SearchIndices::SearchServer.any_instance.expects(:index)
      .with("test-index")
      .returns(mock_index)

    worker = Indexer::BulkIndexWorker.new
    worker.perform("test-index", SAMPLE_DOCUMENT_HASHES)
  end

  it "retries_when_index_locked" do
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

  it "forwards_to_failure_queue" do
    stub_message = {}
    GovukError.expects(:notify).with(Indexer::FailedJobException.new, extra: stub_message)
    fail_block = Indexer::BulkIndexWorker.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
