require "test_helper"
require "search/search_builder"

class BestBetsTest < ShouldaUnitTestCase
  context "when best bets is disabled in debug" do
    should "return the query without modification" do
      builder = QueryComponents::BestBets.new(Search::SearchParameters.new(debug: { disable_best_bets: true }))

      result = builder.wrap('QUERY')

      assert_equal result, 'QUERY'
    end
  end

  context "with a single best bet url" do
    should "include the ID of the document in the results" do
      builder = QueryComponents::BestBets.new
      builder.stubs best_bets: { 1 => ['/best-bet'] }

      result = builder.wrap('QUERY')

      expected = { bool: { should: ['QUERY', { function_score: { query: { ids: { values: ["/best-bet"] } }, boost_factor: 1000000 } }] } }
      assert_equal expected, result
    end
  end

  context "with two best bet urls on different positions" do
    should "include IDs of the documents in the results" do
      builder = QueryComponents::BestBets.new
      builder.stubs best_bets: { 1 => ['/best-bet'], 2 => ['/other-best-bet'] }

      result = builder.wrap('QUERY')

      expected = {
        bool: {
          should: ['QUERY',
                   { function_score: { query: { ids: { values: ["/best-bet"] } }, boost_factor: 2000000 } },
                   { function_score: { query: { ids: { values: ["/other-best-bet"] } }, boost_factor: 1000000 } }
            ]
        }
      }

      assert_equal expected, result
    end
  end

  context "with two best bet urls on the same position" do
    should "include IDs of the documents in the results" do
      builder = QueryComponents::BestBets.new
      builder.stubs best_bets: { 1 => ['/best-bet', '/other-best-bet'] }

      result = builder.wrap('QUERY')

      expected = { bool: { should: ['QUERY', { function_score: { query: { ids: { values: ["/best-bet", "/other-best-bet"] } }, boost_factor: 1000000 } }] } }
      assert_equal expected, result
    end
  end

  context "with a 'worst bet'" do
    should "completely exclude the documents from the results" do
      builder = QueryComponents::BestBets.new
      builder.stubs worst_bets: ['/worst-bet', '/other-worst-bet']

      result = builder.wrap({})

      expected = { bool: { should: [{}], must_not: [{ ids: { values: ["/worst-bet", "/other-worst-bet"] } }] } }
      assert_equal expected, result
    end
  end
end
