require 'spec_helper'

RSpec.describe 'MissingMetadataTest' do
  it "finds missing content_id" do
    commit_document(
      'government_test',
      'link' => '/path/to_page',
    )

    runner = MissingMetadata::Runner.new('content_id', search_config: SearchConfig.default_instance, logger: io)
    results = runner.retrieve_records_with_missing_value

    expect([{ _id: '/path/to_page', index: 'government_test' }]).to eq results
  end

  it "ignores already set content_id" do
    commit_document(
      'government_test',
      'link' => '/path/to_page',
      'content_id' => '8aea1742-9cc6-4dfb-a63b-12c3e66a601f',
    )

    runner = MissingMetadata::Runner.new('content_id', search_config: SearchConfig.default_instance, logger: io)
    results = runner.retrieve_records_with_missing_value

    expect(results).to be_empty
  end

  it "finds missing document_type" do
    commit_document(
      'government_test',
      'link' => '/path/to_page',
      'content_id' => '8aea1742-9cc6-4dfb-a63b-12c3e66a601f',
    )

    runner = MissingMetadata::Runner.new('content_store_document_type', search_config: SearchConfig.default_instance, logger: io)
    results = runner.retrieve_records_with_missing_value

    expect([{ _id: '/path/to_page', index: 'government_test', content_id: '8aea1742-9cc6-4dfb-a63b-12c3e66a601f' }]).to eq results
  end

  it "ignores already set document_type" do
    commit_document(
      'government_test',
      'link' => '/path/to_page',
      'content_id' => '8aea1742-9cc6-4dfb-a63b-12c3e66a601f',
      'content_store_document_type' => 'guide',
    )

    runner = MissingMetadata::Runner.new('content_store_document_type', search_config: SearchConfig.default_instance, logger: io)
    results = runner.retrieve_records_with_missing_value

    expect(results).to be_empty
  end

  def io
    @io ||= StringIO.new
  end
end
