require "test_helper"
require "search/query_builder"

class CoreQueryTest < ShouldaUnitTestCase
  context "search with debug disabling use of synonyms" do
    should "use the query_with_old_synonyms analyzer" do
      builder = QueryComponents::CoreQuery.new(search_query_params)

      query = builder.minimum_should_match("_all")

      assert_match(/query_with_old_synonyms/, query.to_s)
    end

    should "not use the query_with_old_synonyms analyzer" do
      builder = QueryComponents::CoreQuery.new(search_query_params(debug: { disable_synonyms: true }))

      query = builder.minimum_should_match("_all")

      refute_match(/query_with_old_synonyms/, query.to_s)
    end
  end

  context "the search query" do
    should "down-weight results which match fewer words in the search term" do
      builder = QueryComponents::CoreQuery.new(search_query_params)

      query = builder.minimum_should_match("_all")
      assert_match(/"2<2 3<3 7<50%"/, query.to_s)
    end
  end
end
