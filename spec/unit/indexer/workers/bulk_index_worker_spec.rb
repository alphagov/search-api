require 'spec_helper'

RSpec.describe Indexer::BulkIndexWorker do
  SAMPLE_DOCUMENT_HASHES = %w(foo bar baz).map do |slug|
    { link: "/#{slug}", title: slug.capitalize }
  end

  it "indexes documents" do
    mock_index = double("index")
    expect(mock_index).to receive(:bulk_index).with(SAMPLE_DOCUMENT_HASHES)
    allow_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with("test-index")
      .and_return(mock_index)

    worker = described_class.new
    worker.perform("test-index", SAMPLE_DOCUMENT_HASHES)
  end

  it "retries when index locked" do
    lock_delay = described_class::LOCK_DELAY

    mock_index = double("index")
    expect(mock_index).to receive(:bulk_index).and_raise(SearchIndices::IndexLocked)
    allow_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with("test-index")
      .and_return(mock_index)

    expect(described_class).to receive(:perform_in)
      .with(lock_delay, "test-index", SAMPLE_DOCUMENT_HASHES)

    worker = described_class.new
    worker.perform("test-index", SAMPLE_DOCUMENT_HASHES)
  end

  it "forwards to failure queue" do
    stub_message = {}
    expect(GovukError).to receive(:notify).with(Indexer::FailedJobException.new, extra: stub_message)
    fail_block = described_class.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
