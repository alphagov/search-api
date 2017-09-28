require 'spec_helper'

RSpec.describe 'SettingsTest', tags: ['integration'] do
  allow_elasticsearch_connection

  it "default" do
    assert_tokenisation :default,
      "It's A Small’s World" => %w(it small world),
      "It's Mitt’s" => %w(it mitt)
  end

  it "uses_correct_stemming" do
    assert_tokenisation :default,
      "news" => ["news"]
  end

  it "query_default" do
    assert_tokenisation :query_default,
      "It's A Small World" => %w(it small world),
      "It's, It’s Mr. O'Neill" => %w(it it mr oneil)
  end

  it "shingled_query_analyzer" do
    assert_tokenisation :shingled_query_analyzer,
      "Hello Hallo" => ["hello", "hello hallo", "hallo"],
      "H'lo ’Hallo" => ["h'lo", "h'lo hallo", "hallo"]
  end

  it "exact_match" do
    assert_tokenisation :exact_match,
      "It’s A Small W'rld" => ["it's a small w'rld"]
  end

  it "best_bet_stemmed_match" do
    assert_tokenisation :best_bet_stemmed_match,
      "It’s A Small W'rld" => %w(it a small wrld)
  end

  it "spelling_analyzer" do
    assert_tokenisation :spelling_analyzer,
      "It’s Grammed" => ["its", "its grammed", "grammed"]
  end

  it "string_for_sorting" do
    assert_tokenisation :string_for_sorting,
      "It's A Small W’rld" => ["its a small wrld"]
  end

  it "with_shingles_analyzer" do
    assert_tokenisation :with_shingles,
      "The small brown dog" => ["the small", "small brown", "brown dog"]
  end

  it "with_id_codes_analyzer" do
    assert_tokenisation :with_id_codes,
      "You will need forms A.10, P11,  P 12, P 13D, P45X and P-60. Z:90, \"V 50\" B_52 C4 3/2007  M\\18. :/!  (RA) 1002" =>
      %w{a10 10 p11 p12 12 p13d 13d p45xand p45x p60 60 z90 90 v50 50 b52 52c4 52 c43 c4 32007 2007m 2007 m18 18 ra1002 1002}
  end

private

  # Verifies that certain input will be tokenised as expected by the specified
  # analyzer.
  def assert_tokenisation(analyzer, assertions)
    assertions.each do |query, expected_output|
      tokens = fetch_tokens_for_analyzer(query, analyzer)
      assert_equal expected_output, tokens
    end
  end

  def fetch_tokens_for_analyzer(query, analyzer)
    result = client.indices.analyze(index: 'government_test', analyzer: analyzer.to_s, body: query)
    mappings = result['tokens']
    mappings.map { |mapping| mapping['token'] }
  end
end
