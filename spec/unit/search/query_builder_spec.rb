require "spec_helper"

RSpec.describe Search::QueryBuilder do
  # rubocop:disable RSpec/AnyInstance
  before do
    allow_any_instance_of(LegacyClient::IndexForSearch).to receive(:real_index_names).and_return(%w(govuk_test))
    allow_any_instance_of(Search::BestBetsChecker).to receive(:best_bets).and_return([])
    allow_any_instance_of(Search::BestBetsChecker).to receive(:worst_bets).and_return([])
  end
  # rubocop:enable RSpec/AnyInstance

  context "with a simple search query" do
    it "return a correct query object" do
      builder = builder_with_params(start: 11, count: 34, return_fields: ["a_field"])

      result = builder.payload
      expect(result[:from]).to eq(11)
      expect(result[:size]).to eq(34)
      expect(result[:_source][:includes]).to include("a_field")
      expect(result.key?(:query)).to be_truthy
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
      content_index_names: SearchConfig.content_index_names,
      metasearch_index: SearchConfig.default_instance.metasearch_index,
    )
  end
end
