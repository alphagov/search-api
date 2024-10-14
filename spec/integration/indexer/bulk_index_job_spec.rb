require "spec_helper"
require "securerandom"

RSpec.describe Indexer::BulkIndexJob do
  let(:index_name) { "government_test" }

  let(:sample_document_hashes) do
    %w[foo bar baz].map do |slug|
      { "link" => "/#{slug}", "title" => slug.capitalize, "document_type" => "edition" }
    end
  end

  it "indexes documents" do
    stub_request_to_publishing_api
    described_class.new.perform(index_name, sample_document_hashes)

    sample_document_hashes.each do |document|
      expect_document_is_in_rummager(document, id: document["link"], index: index_name)
    end
  end

  it "retries when index locked" do
    with_just_one_cluster
    lock_delay = described_class::LOCK_DELAY

    mock_index = double(SearchIndices::Index)
    expect(mock_index).to receive(:bulk_index).and_raise(SearchIndices::IndexLocked)
    allow_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with("test-index")
      .and_return(mock_index)
    expect(described_class).to receive(:perform_in)
      .with(lock_delay, "test-index", sample_document_hashes)

    job = described_class.new
    job.perform("test-index", sample_document_hashes)
  end

  it "forwards to failure queue" do
    stub_message = {}
    expect(GovukError).to receive(:notify).with(Indexer::FailedJobException.new, extra: stub_message)

    fail_block = described_class.sidekiq_retries_exhausted_block
    fail_block.call(stub_message)
  end

  def stub_request_to_publishing_api
    endpoint = "#{Plek.find('publishing-api')}/lookup-by-base-path"

    stub_request(:post, endpoint).to_return(status: 200, body: {}.to_json)
  end
end
