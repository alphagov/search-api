require "spec_helper"
require "spec/unit/helpers/ranker_test_helpers"

RSpec.describe LearnToRank::Reranker do
  include RankerTestHelpers

  let(:reranked) { described_class.new.rerank(query: query, es_results: search_results) }

  let(:feature_sets) do
    LearnToRank::FeatureSets.new.call(query, search_results)
  end

  describe "#reranked" do
    context "when there are no search results" do
      let(:query) { nil }
      let(:search_results) { [] }
      it "returns an empty array without calling ranker" do
        expect(reranked).to eq([])
      end
    end

    context "when there are search results" do
      it "returns an array of new ranks" do
        stub_request_to_ranker(feature_sets, [1, 2])
        expect(reranked.count).to eq(2)
        expect(reranked.first.dig("_source", "title")).to eq("More relevant document")
        expect(reranked.second.dig("_source", "title")).to eq("More popular document")
      end
    end

    context "when the ranker is unavailable" do
      it "returns an array of ranks in descending order, to preserve original rank" do
        stub_ranker_is_unavailable
        expect(reranked.count).to eq(2)
        expect(reranked.first.dig("_source", "title")).to eq("More popular document")
        expect(reranked.second.dig("_source", "title")).to eq("More relevant document")
      end
    end
  end
end
