require 'spec_helper'

RSpec.describe Search::QueryBuilder do
  before do
    allow_any_instance_of(Search::BestBetsChecker).to receive(:best_bets).and_return([])
    allow_any_instance_of(Search::BestBetsChecker).to receive(:worst_bets).and_return([])
  end

  context "with a simple search query" do
    it "return a correct query object" do
      builder = builder_with_params(start: 11, count: 34, return_fields: ['a_field'])

      result = builder.payload
      assert_equal 11, result[:from]
      assert_equal 34, result[:size]
      assert result[:fields].include?('a_field')
      assert result.key?(:query)
    end
  end

  context "more like this" do
    it "call the payload for a more like this query" do
      builder = builder_with_params(similar_to: %{"/hello-world"})

      expect(builder).to receive(:more_like_this_query_hash).once

      # TODO: assert what the payload looks like
      builder.payload
    end
  end

  def builder_with_params(params)
    described_class.new(
      search_params: Search::QueryParameters.new({ filters: [] }.merge(params)),
      content_index_names: SearchConfig.instance.content_index_names,
      metasearch_index: SearchConfig.instance.metasearch_index
    )
  end
end
