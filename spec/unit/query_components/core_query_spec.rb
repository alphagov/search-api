require 'spec_helper'

RSpec.describe QueryComponents::CoreQuery do
  context "search with debug disabling use of synonyms" do
    it "use the query_with_old_synonyms analyzer" do
      builder = described_class.new(search_query_params)

      query = builder.minimum_should_match("_all")

      expect(query.to_s).to match(/query_with_old_synonyms/)
    end

    it "not use the query_with_old_synonyms analyzer" do
      builder = described_class.new(search_query_params(debug: { disable_synonyms: true }))

      query = builder.minimum_should_match("_all")

      expect(query.to_s).not_to match(/query_with_old_synonyms/)
    end
  end

  context "the search query" do
    it "down-weight results which match fewer words in the search term" do
      builder = described_class.new(search_query_params)

      query = builder.minimum_should_match("_all")
      expect(query.to_s).to match(/"2<2 3<3 7<50%"/)
    end
  end
end
