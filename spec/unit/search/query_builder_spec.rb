require "spec_helper"

RSpec.describe Search::QueryBuilder do
  before do
    allow_any_instance_of(Search::BestBetsChecker).to receive(:best_bets).and_return([])
    allow_any_instance_of(Search::BestBetsChecker).to receive(:worst_bets).and_return([])
  end

  context "with a simple search query" do
    it "return a correct query object" do
      builder = builder_with_params(start: 11, count: 34, return_fields: %w[a_field])

      result = builder.payload
      expect(result[:from]).to eq(11)
      expect(result[:size]).to eq(34)
      expect(result[:_source][:includes]).to include("a_field")
      expect(result).to be_key(:query)
    end
  end

  def builder_with_params(params)
    described_class.new(
      search_params: Search::QueryParameters.new({ filters: [] }.merge(params)),
      metasearch_index: SearchConfig.default_instance.metasearch_index,
    )
  end
end
