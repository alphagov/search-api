require 'spec_helper'

RSpec.describe SynonymParser do
  it "identifies the search time synonyms" do
    config = [{ "search" => "jelly fish => jellyfish, fish" }]

    @index_synonyms, @search_synonyms = described_class.new.parse(config)

    expect_search_synonyms_contain "jelly fish => jellyfish, fish"
  end

  it "identifies the index time synonyms" do
    config = [{ "index" => "jelly fish => jellyfish, fish" }]

    @index_synonyms, @search_synonyms = described_class.new.parse(config)

    expect_index_synonyms_contain "jelly fish => jellyfish, fish"
  end

  it "configures synonyms with the same term and the same mappings (marked as 'both')" do
    config = [{ "both" => "jelly fish => jellyfish, fish" }]

    @index_synonyms, @search_synonyms = described_class.new.parse(config)

    expect_search_synonyms_contain "jelly fish => jellyfish, fish"
    expect_index_synonyms_contain "jelly fish => jellyfish, fish"
  end

  it "configures synonyms where the term is the same, but the mappings are different" do
    config = [{ "search" => "jelly fish => jellyfish, fish" }, { "index" => "jelly fish => jellyfish" }]

    @index_synonyms, @search_synonyms = described_class.new.parse(config)

    expect_search_synonyms_contain "jelly fish => jellyfish, fish"
    expect_index_synonyms_contain "jelly fish => jellyfish"
  end

  it "configures synonyms in the correct Elasticsearch settings format" do
    config = [
      { "both" => "pig, micropig" },
      { "search" => "mcrpig => micropig" },
      { "index" => "tiny pig => tiny pig, micropig" },
    ]

    @index_synonyms, @search_synonyms = described_class.new.parse(config)

    expect(@index_synonyms.es_config).to eq({
        type: :synonym,
        synonyms: ["pig, micropig", "tiny pig => tiny pig, micropig"]
      })
    expect(@search_synonyms.es_config).to eq({
        type: :synonym,
        synonyms: ["pig, micropig", "mcrpig => micropig"]
      })
  end

  def expect_search_synonyms_contain(expected)
    expect(@search_synonyms.es_config[:synonyms]).to include(expected)
  end

  def expect_index_synonyms_contain(expected)
    expect(@index_synonyms.es_config[:synonyms]).to include(expected)
  end
end
