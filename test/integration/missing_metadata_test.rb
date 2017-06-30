require "integration_test_helper"
require 'missing_metadata/runner'
require 'gds_api/test_helpers/publishing_api_v2'

class MissingMetadataTest < IntegrationTest
  def test_finds_missing_content_id
    commit_document(
      'mainstream_test',
      'link' => '/path/to_page',
    )

    runner = MissingMetadata::Runner.new('content_id', search_config: stubbed_search_config, logger: io)
    results = runner.retrieve_records_with_missing_value

    assert_equal [{ _id: '/path/to_page', index: 'mainstream_test' }], results
  end

  def test_ignores_already_set_content_id
    commit_document(
      'mainstream_test',
      'link' => '/path/to_page',
      'content_id' => '8aea1742-9cc6-4dfb-a63b-12c3e66a601f',
    )

    runner = MissingMetadata::Runner.new('content_id', search_config: stubbed_search_config, logger: io)
    results = runner.retrieve_records_with_missing_value

    assert_empty results
  end

  def test_finds_missing_document_type
    commit_document(
      'mainstream_test',
      'link' => '/path/to_page',
      'content_id' => '8aea1742-9cc6-4dfb-a63b-12c3e66a601f',
    )

    runner = MissingMetadata::Runner.new('content_store_document_type', search_config: stubbed_search_config, logger: io)
    results = runner.retrieve_records_with_missing_value

    assert_equal [{ _id: '/path/to_page', index: 'mainstream_test', content_id: '8aea1742-9cc6-4dfb-a63b-12c3e66a601f' }], results
  end

  def test_ignores_already_set_document_type
    commit_document(
      'mainstream_test',
      'link' => '/path/to_page',
      'content_id' => '8aea1742-9cc6-4dfb-a63b-12c3e66a601f',
      'content_store_document_type' => 'guide',
    )

    runner = MissingMetadata::Runner.new('content_store_document_type', search_config: stubbed_search_config, logger: io)
    results = runner.retrieve_records_with_missing_value

    assert_empty results
  end

  def io
    @io ||= StringIO.new
  end
end
