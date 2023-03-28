require "spec_helper"

RSpec.describe QueryComponents::CoreQuery do
  context "the search query" do
    it "uses the synonyms analyzer" do
      builder = described_class.new(search_query_params)

      query = builder.minimum_should_match("all_searchable_text", "text to search over")

      expect(query.to_s).to match(/all_searchable_text\.synonym/)
    end

    it "down-weight results which match fewer words in the search term" do
      builder = described_class.new(search_query_params)

      query = builder.minimum_should_match("_all", "text to search over")
      expect(query.to_s).to match(/"2<2 3<3 7<50%"/)
    end

    it "includes field boosts for unquoted query" do
      builder = described_class.new(
        search_query_params(boost_fields: %w[custom_field]),
      )

      query = builder.unquoted_phrase_query("income tax")

      expect(query.to_s).to include("custom_field.synonym")
    end

    it "includes field boosts for quoted query" do
      builder = described_class.new(
        search_query_params(boost_fields: %w[custom_field]),
      )

      query = builder.quoted_phrase_query("income tax")

      expect(query.to_s).to include("custom_field.no_stop")
    end
  end

  context "the search query with synonyms disabled" do
    it "uses the default analyzer" do
      builder = described_class.new(search_query_params(debug: { disable_synonyms: true }))

      query = builder.minimum_should_match("_all", "text to search over")

      expect(query.to_s).to match(/default/)
      expect(query.to_s).not_to match(/all_searchable_text\.synonym/)
    end
  end

  context "the B variant of shingles" do
    it "makes unquoted search queries match bigrams" do
      builder = described_class.new(
        search_query_params(ab_tests: { shingles: "B" }),
      )

      query = builder.unquoted_phrase_query("income tax")

      expect(query.to_s).to include("shingled_query_analyzer")
    end
  end
end
