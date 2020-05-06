require "spec_helper"

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
      synonyms: ["pig, micropig", "tiny pig => tiny pig, micropig"],
    })
    expect(@search_synonyms.es_config).to eq({
      type: :synonym,
      synonyms: ["pig, micropig", "mcrpig => micropig"],
    })
  end

  it "rejects unknown synonym keys" do
    config = [
      { "other" => "pig, micropig" },
    ]

    expect {
      described_class.new.parse(config)
    }.to raise_error(SynonymParser::InvalidSynonymConfig)
  end

  it "rejects missing synonym definitions" do
    config = [
      { "search" => "micropig =>" },
    ]

    expect {
      described_class.new.parse(config)
    }.to raise_error(SynonymParser::InvalidSynonymConfig)
  end

  context "duplicate validation" do
    it "rejects duplicate terms with the 'search' key" do
      config = [
        { "search" => "mcrpig => pig" },
        { "search" => "mcrpig => micropig" },
      ]

      expect {
        described_class.new.parse(config)
      }.to raise_error(SynonymParser::InvalidSynonymConfig)
    end

    it "rejects duplicate terms with the 'index' key" do
      config = [
        { "index" => "mcrpig => pig" },
        { "index" => "mcrpig => micropig" },
      ]

      expect {
        described_class.new.parse(config)
      }.to raise_error(SynonymParser::InvalidSynonymConfig)
    end

    it "rejects duplicate terms with 'both' and 'search' key" do
      config = [
        { "both" => "mcrpig => pig" },
        { "search" => "mcrpig => micropig" },
      ]

      expect {
        described_class.new.parse(config)
      }.to raise_error(SynonymParser::InvalidSynonymConfig)
    end

    it "rejects duplicate terms with 'both' and 'index' key" do
      config = [
        { "both" => "mcrpig => pig" },
        { "index" => "mcrpig => micropig" },
      ]

      expect {
        described_class.new.parse(config)
      }.to raise_error(SynonymParser::InvalidSynonymConfig)
    end

    it "rejects duplicate terms when terms are grouped" do
      config = [
        { "index" => "mcrpig, mycropig => pig" },
        { "index" => "mcrpig => micropig" },
      ]

      expect {
        described_class.new.parse(config)
      }.to raise_error(SynonymParser::InvalidSynonymConfig)
    end

    it "rejects duplicate synonyms defined using both arrow and comma syntax" do
      config = [
        { "index" => "pig, mcrpig" },
        { "both" => "mcrpig => micropig" },
      ]

      expect {
        described_class.new.parse(config)
      }.to raise_error(SynonymParser::InvalidSynonymConfig)
    end

    it "allows duplicate synonym definitions" do
      config = [
        { "index" => "mcrpig => micropig" },
        { "index" => "mycropig => micropig" },
      ]

      @index_synonyms, @search_synonyms = described_class.new.parse(config)

      expect_index_synonyms_contain "mcrpig => micropig"
      expect_index_synonyms_contain "mycropig => micropig"
    end
  end

  it "rejects hashes with multiple synonyms" do
    config = [
      {
        "index" => "mcrpig => micropig",
        "both" => "mycropig => micropig",
        "search" => "miicropig => micropig",
      },
    ]

    expect {
      described_class.new.parse(config)
    }.to raise_error(SynonymParser::InvalidSynonymConfig)
  end

  def expect_search_synonyms_contain(expected)
    expect(@search_synonyms.es_config[:synonyms]).to include(expected)
  end

  def expect_index_synonyms_contain(expected)
    expect(@index_synonyms.es_config[:synonyms]).to include(expected)
  end
end
