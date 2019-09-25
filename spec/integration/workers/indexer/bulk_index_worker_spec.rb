require "spec_helper"
require "securerandom"

RSpec.describe Indexer::BulkIndexWorker do
  let(:index_name) { "government_test" }

  SAMPLE_DOCUMENT_HASHES = %w(foo bar baz).map do |slug|
    { "link" => "/#{slug}", "title" => slug.capitalize, "document_type" => "edition" }
  end

  it "indexes documents" do
    stub_request_to_publishing_api
    described_class.new.perform(index_name, SAMPLE_DOCUMENT_HASHES)

    SAMPLE_DOCUMENT_HASHES.each { |document|
      expect_document_is_in_rummager(document, id: document["link"], index: index_name)
    }
  end

  it "retries when index locked" do
    with_just_one_cluster
    lock_delay = described_class::LOCK_DELAY

    mock_index = double(SearchIndices::Index) # rubocop:disable RSpec/VerifiedDoubles
    # rubocop:disable RSpec/MessageSpies
    expect(mock_index).to receive(:bulk_index).and_raise(SearchIndices::IndexLocked)
    allow_any_instance_of(SearchIndices::SearchServer).to receive(:index) # rubocop:disable RSpec/AnyInstance
      .with("test-index")
      .and_return(mock_index)
    expect(described_class).to receive(:perform_in)
      .with(lock_delay, "test-index", SAMPLE_DOCUMENT_HASHES)
    # rubocop:enable RSpec/MessageSpies

    worker = described_class.new
    worker.perform("test-index", SAMPLE_DOCUMENT_HASHES)
  end

  it "forwards to failure queue" do
    stub_message = {}
    # rubocop:disable RSpec/MessageSpies
    expect(GovukError).to receive(:notify).with(Indexer::FailedJobException.new, extra: stub_message)
    # rubocop:enable RSpec/MessageSpies
    fail_block = described_class.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end

  def stub_request_to_publishing_api
    endpoint = Plek.current.find("publishing-api") + "/lookup-by-base-path"

    stub_request(:post, endpoint).to_return(status: 200, body: {}.to_json)
  end
end
