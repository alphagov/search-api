require 'spec_helper'

RSpec.describe Indexer::DeleteWorker do
  # rubocop:disable RSpec/MessageSpies
  it "deletes documents" do
    mock_index = double("index")
    expect(mock_index).to receive(:delete).with("/foobang")
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with("test-index")
      .and_return(mock_index)

    worker = described_class.new
    worker.perform("test-index", "edition", "/foobang")
  end
  # rubocop:enable RSpec/MessageSpies

  it "retries when index locked" do
    lock_delay = described_class::LOCK_DELAY
    mock_index = double("index")
    expect(mock_index).to receive(:delete).and_raise(SearchIndices::IndexLocked)
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with("test-index")
      .and_return(mock_index)

    expect(described_class).to receive(:perform_in)
      .with(lock_delay, "test-index", "edition", "/foobang")

    worker = described_class.new
    worker.perform("test-index", "edition", "/foobang")
  end

  it "forwards to failure queue" do
    stub_message = {}
    expect(GovukError).to receive(:notify).with(Indexer::FailedJobException.new, extra: stub_message)
    fail_block = described_class.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end
end
