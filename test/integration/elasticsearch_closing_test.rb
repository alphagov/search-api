require "integration_test_helper"

class ElasticsearchClosingTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
    create_test_index
  end

  def teardown
    clean_test_indexes
  end

  def test_should_fail_to_insert_or_get_when_index_closed
    index = search_server.index_group(DEFAULT_INDEX_NAME).current
    index.close

    assert_raises Elasticsearch::BulkIndexFailure do
      index.add([sample_document])
    end
  end
end
