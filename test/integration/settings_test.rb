require "integration_test_helper"

class SettingsTest < IntegrationTest
  def setup
    enable_test_index_connections
    refresh_test_index
  end

  def test_spelling_analyzer_normalizes_and_lowercases_in_bigrams
    query = "A'pos B’pos"
    analyzer = "spelling_analyzer"

    tokens = fetch_tokens_for_analyzer(query, analyzer)

    assert_equal ["a'pos", "a'pos b'pos", "b'pos"], tokens
  end

  private

  def fetch_tokens_for_analyzer(query, analyzer)
    result = client.post('government-test/_analyze?analyzer=' + analyzer, query)
    mappings = JSON.parse(result)['tokens']
    mappings.map { |mapping| mapping['token'] }
  end

  def refresh_test_index
    index_name = 'government-test'
    try_remove_test_index(index_name)
    create_test_index(index_name)
  end

  def client
    @client ||= Elasticsearch::Client.new('http://localhost:9200/')
  end
end
