require "integration_test_helper"

class SettingsTest < IntegrationTest
  def test_default
    assert_tokenisation :default,
      "It's A Small’s World" => ["it", "small", "world"],
      "It's Mitt’s" => ["it", "mitt"]
  end

  def test_query_default
    assert_tokenisation :query_default,
      "It's A Small World" => ["it", "small", "world"],
      "It's, It’s Mr. O'Neill" => ["it", "it", "mr", "oneil"]
  end

  def test_shingled_query_analyzer
    assert_tokenisation :shingled_query_analyzer,
      "Hello Hallo" => ["hello", "hello hallo", "hallo"],
      "H'lo ’Hallo" => ["h'lo", "h'lo hallo", "hallo"]
  end

  def test_exact_match
    assert_tokenisation :exact_match,
      "It’s A Small W'rld" => ["it's a small w'rld"]
  end

  def test_best_bet_stemmed_match
    assert_tokenisation :best_bet_stemmed_match,
      "It’s A Small W'rld" => ["it", "a", "small", "wrld"]
  end

  def test_spelling_analyzer
    assert_tokenisation :spelling_analyzer,
      "It’s Grammed" => ["its", "its grammed", "grammed"]
  end

  def test_string_for_sorting
    assert_tokenisation :string_for_sorting,
      "It's A Small W’rld" => ["its a small wrld"]
  end

  def test_with_shingles_analyzer
    assert_tokenisation :with_shingles,
      "The small brown dog" => ["the small", "small brown", "brown dog"]
  end

private

  # Verifies that certain input will be tokenised as expected by the specified
  # analyzer. 
  def assert_tokenisation(analyzer, assertions)
    enable_test_index_connections
    refresh_test_index

    assertions.each do |query, expected_output|
      tokens = fetch_tokens_for_analyzer(query, analyzer)
      assert_equal expected_output, tokens
    end
  end

  def fetch_tokens_for_analyzer(query, analyzer)
    result = client.post('government-test/_analyze?analyzer=' + analyzer.to_s, query)
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
