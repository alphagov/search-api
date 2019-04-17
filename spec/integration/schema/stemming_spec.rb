require 'spec_helper'

RSpec.describe 'SettingsTest' do
  describe 'the default analyzer' do
    it "reduces words to their stems" do
      expect_tokenisation :default,
        "It's A Small’s World" => %w(it small world),
        "It's Mitt’s" => %w(it mitt)
    end

    it "doesn't over-stem important words" do
      expect_tokenisation :default,
        "news" => %w(news)
    end
  end

  describe "exact matching" do
    it "preserves quotes" do
      expect_tokenisation :exact_match,
        "It’s A Small W'rld" => ["it's a small w'rld"]
    end

    it "preserves stopwords" do
      expect_tokenisation :exact_match,
        "to" => %w(to)
    end
  end

  describe "searchable text" do
    it "preserves stopwords" do
      expect_tokenisation :searchable_text,
        "to be or not to be" => %w(to be or not to be)
    end
  end

  it "stems best bets" do
    expect_tokenisation :best_bet_stemmed_match,
      "It’s A Small W'rld" => %w(it a small wrld)
  end

  it "uses the default shingle filter for spelling suggestions" do
    expect_tokenisation :spelling_analyzer,
      "It’s Grammed" => ["its", "its grammed", "grammed"]
  end

  it "ignores quotes for sorting" do
    expect_tokenisation :string_for_sorting,
      "It's A Small W’rld" => ["its a small wrld"]
  end

private

  # Verifies that certain input will be tokenised as expected by the specified
  # analyzer.
  def expect_tokenisation(analyzer, assertions)
    assertions.each do |query, expected_output|
      tokens = fetch_tokens_for_analyzer(query, analyzer)
      expect(tokens).to eq(expected_output)
    end
  end

  def fetch_tokens_for_analyzer(query, analyzer)
    result = client.indices.analyze(index: 'government_test', analyzer: analyzer.to_s, text: query)
    mappings = result['tokens']
    mappings.map { |mapping| mapping['token'] }
  end
end
