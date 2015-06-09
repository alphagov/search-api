require "integration_test_helper"

class SettingsTest < IntegrationTest
  def test_default
    assert_tokenisation :default,
      "It's A Small’s World" => ["it", "small", "world"],
      "It's Mitt’s" => ["it", "mitt"]
  end

  def test_uses_correct_stemming
    assert_tokenisation :default,
      "news" => ["news"]
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

  def test_with_id_codes_analyzer
    assert_tokenisation :with_id_codes,
      "You will need forms A.10, P11,  P 12, P 13D, P45X and P-60. Z:90, \"V 50\" B_52 C4 3/2007  M\\18. :/!  (RA) 1002" =>
      %w{a10 10 p11 p12 12 p13d 13d p45xand p45x p60 60 z90 90 v50 50 b52 52c4 52 c43 c4 32007 2007m 2007 m18 18 ra1002 1002}
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
