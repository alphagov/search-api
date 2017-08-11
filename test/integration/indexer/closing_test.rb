require 'integration_test_helper'

class ElasticsearchClosingTest < IntegrationTest
  def setup
    super
    stub_tagging_lookup
  end

  def test_should_fail_to_insert_or_get_when_index_closed
    index = search_server.index_group(TestIndexHelpers::DEFAULT_INDEX_NAME).current
    index.close

    assert_raises Indexer::BulkIndexFailure do
      index.add([sample_document])
    end

    # Re-opening the index again, as they are not recreated on each test run
    # anymore.
    client.indices.open(index: TestIndexHelpers::DEFAULT_INDEX_NAME)
  end
end
