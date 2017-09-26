require 'spec_helper'

RSpec.describe QueryComponents::CoreQuery, tags: ['shoulda'] do
  context "search with debug disabling use of synonyms" do
    it "use the query_with_old_synonyms analyzer" do
      builder = described_class.new(search_query_params)

      query = builder.minimum_should_match("_all")

      assert_match(/query_with_old_synonyms/, query.to_s)
    end

    it "not use the query_with_old_synonyms analyzer" do
      builder = described_class.new(search_query_params(debug: { disable_synonyms: true }))

      query = builder.minimum_should_match("_all")

      refute_match(/query_with_old_synonyms/, query.to_s)
    end
  end

  context "the search query" do
    it "down-weight results which match fewer words in the search term" do
      builder = described_class.new(search_query_params)

      query = builder.minimum_should_match("_all")
      assert_match(/"2<2 3<3 7<50%"/, query.to_s)
    end
  end
end
