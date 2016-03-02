require "test_helper"
require "search/query_builder"

class QueryBuilderTest < ShouldaUnitTestCase
  def setup
    Search::BestBetsChecker.any_instance.stubs best_bets: [], worst_bets: []
  end

  context "with a simple search query" do
    should "return a correct query object" do
      builder = builder_with_params(start: 11, count: 34, return_fields: ['a_field'])

      result = builder.payload

      assert_equal 11, result[:from]
      assert_equal 34, result[:size]
      assert result[:fields].include?('a_field')
      assert result.key?(:query)
    end
  end

  def builder_with_params(params)
    Search::QueryBuilder.new(
      Search::QueryParameters.new({ filters: [] }.merge(params))
    )
  end
end
