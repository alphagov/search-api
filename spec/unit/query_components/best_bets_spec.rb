require "spec_helper"

RSpec.describe QueryComponents::BestBets do
  context "when best bets is disabled in debug" do
    it "return the query without modification" do
      builder = described_class.new(
        metasearch_index: SearchConfig.default_instance.metasearch_index,
        search_params: Search::QueryParameters.new(debug: { disable_best_bets: true }),
      )

      result = builder.wrap("QUERY")

      expect(result).to eq("QUERY")
    end
  end

  context "with a single best bet url" do
    it "include the ID of the document in the results" do
      builder = described_class.new(metasearch_index: SearchConfig.default_instance.metasearch_index)
      allow(builder).to receive(:best_bets).and_return(1 => ["/best-bet"])

      result = builder.wrap("QUERY")

      expected = { bool: { should: ["QUERY", { function_score: { query: { terms: { link: ["/best-bet"] } }, weight: 1_000_000 } }] } }
      expect(result).to eq(expected)
    end
  end

  context "with two best bet urls on different positions" do
    it "include IDs of the documents in the results" do
      builder = described_class.new(metasearch_index: SearchConfig.default_instance.metasearch_index)
      allow(builder).to receive(:best_bets).and_return(1 => ["/best-bet"], 2 => ["/other-best-bet"])

      result = builder.wrap("QUERY")

      expected = {
        bool: {
          should: ["QUERY",
                   { function_score: { query: { terms: { link: ["/best-bet"] } }, weight: 2_000_000 } },
                   { function_score: { query: { terms: { link: ["/other-best-bet"] } }, weight: 1_000_000 } }],
        },
      }

      expect(result).to eq(expected)
    end
  end

  context "with two best bet urls on the same position" do
    it "include IDs of the documents in the results" do
      builder = described_class.new(metasearch_index: SearchConfig.default_instance.metasearch_index)
      allow(builder).to receive(:best_bets).and_return(1 => ["/best-bet", "/other-best-bet"])

      result = builder.wrap("QUERY")

      expected = { bool: { should: ["QUERY", { function_score: { query: { terms: { link: ["/best-bet", "/other-best-bet"] } }, weight: 1_000_000 } }] } }
      expect(result).to eq(expected)
    end
  end

  context "with a 'worst bet'" do
    it "completely exclude the documents from the results" do
      builder = described_class.new(metasearch_index: SearchConfig.default_instance.metasearch_index)
      allow(builder).to receive(:worst_bets).and_return(["/worst-bet", "/other-worst-bet"])

      result = builder.wrap({})

      expected = { bool: { should: [{}], must_not: [{ terms: { link: ["/worst-bet", "/other-worst-bet"] } }] } }
      expect(result).to eq(expected)
    end
  end
end
