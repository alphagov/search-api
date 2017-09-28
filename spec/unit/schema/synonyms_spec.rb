require 'spec_helper'

RSpec.describe SynonymParser do
  it "map a single word synonym to the same synonym group at index and search time" do
    parse_synonyms(["one"])

    expect_search_synonyms_contain "one=>!S0"
    expect_index_synonyms_contain "one=>!S0"
  end

  it "number the synonym groups differently" do
    parse_synonyms(%w(one two))

    expect_search_synonyms_contain "one=>!S0"
    expect_search_synonyms_contain "two=>!S1"
  end

  it "map a two word synonym to the same synonym group at index and search time" do
    parse_synonyms(["two, 2"])

    expect_search_synonyms_contain "two,2=>!S0"
    expect_index_synonyms_contain "two,2=>!S0"
  end

  it "understand mapping a search phrase to a different phrase in documents" do
    parse_synonyms(["motorbike => motorcycle"])

    expect_search_synonyms_contain "motorbike=>!S0"
    expect_index_synonyms_contain "motorcycle=>!S0"
  end

  it "understand mapping one search phrase to multiple phrases in documents" do
    parse_synonyms(["opening times => opening times, opening hours"])

    expect_search_synonyms_contain "opening times=>!S0"
    expect_index_synonyms_contain "opening times,opening hours=>!S0"
  end

  it "understand mapping multiple search phrases to one phrase in documents" do
    parse_synonyms(["my, your => your"])

    expect_search_synonyms_contain "my,your=>!S0"
    expect_index_synonyms_contain "your=>!S0"
  end

  it "produce correct config for protecting all the generated synonym terms" do
    parse_synonyms(["one", "two, 2"])

    protected_terms = @search_synonyms.protwords_config[:keywords]
    expect(%w{!S0 !S1}).to eq(protected_terms)
  end

  def parse_synonyms(synonyms)
    Dir.mktmpdir do |dir|
      file_contents = "type: synonym\nsynonyms: [\n  '#{synonyms.join("',\n  '")}',\n]\n"
      open("#{dir}/synonyms.yml", "w") do |file|
        file.write(file_contents)
      end

      @index_synonyms, @search_synonyms = described_class.new(dir).parse
    end
  end

  def expect_search_synonyms_contain(expected)
    expect(@search_synonyms.es_config[:synonyms]).to include(expected)
  end

  def expect_index_synonyms_contain(expected)
    expect(@index_synonyms.es_config[:synonyms]).to include(expected)
  end
end
