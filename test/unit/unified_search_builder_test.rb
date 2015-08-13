require "test_helper"
require "unified_search_builder"

class UnifiedSearchBuilderTest < ShouldaUnitTestCase
  def setup
    BestBetsChecker.any_instance.stubs best_bets: [], worst_bets: []
  end

  context "with a simple search query" do
    should "return a correct query object" do
      builder = builder_with_params(start: 11, count: 34, return_fields: ['a_field'])

      result = builder.payload

      assert_equal 11, result[:from]
      assert_equal 34, result[:size]
      assert_equal ['a_field'], result[:fields]
      assert result.key?(:query)
    end
  end

  def builder_with_params(params)
    UnifiedSearchBuilder.new(
      SearchParameters.new({ filters: [] }.merge(params))
    )
  end
end
