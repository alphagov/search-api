require "integration_test_helper"

class ElasticsearchClosingTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
    enable_test_index_connections
    try_remove_test_index
  end

  def teardown
    clean_test_indexes
  end

  # When the index is closed, we don't particularly mind which exception gets
  # raised, so long as it's a client error (4xx) of some kind
  def restclient_4xx_errors
    RestClient::Exceptions::EXCEPTIONS_MAP.select { |code, exception|
      (400..499).include? code
    }.values
  end

  def test_should_fail_to_insert_or_get_when_index_closed
    create_test_index

    index = search_server.index_group(DEFAULT_INDEX_NAME).current
    index.close
    assert_raises *(restclient_4xx_errors + [Elasticsearch::BulkIndexFailure]) do
      index.add([sample_document])
    end

    assert_raises *restclient_4xx_errors do
      index.get("/foobang")
    end
  end
end
