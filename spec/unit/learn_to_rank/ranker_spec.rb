require "spec_helper"
require "spec/unit/helpers/ranker_test_helpers"

RSpec.describe LearnToRank::Ranker do
  include RankerTestHelpers

  let(:ranks) { described_class.new(feature_sets).ranks }

  let(:feature_sets) do
    LearnToRank::FeatureSets.new.call(query, search_results)
  end

  describe "#ranks" do
    context "when there are no search results" do
      let(:query) { nil }
      let(:search_results) { [] }
      it "returns an empty array without calling ranker" do
        expect(ranks).to eq([])
      end
    end

    context "when there are search results" do
      it "returns an array of new ranks" do
        stub_request_to_ranker(feature_sets, [1, 2])
        expect(ranks).to eq([1, 2])
      end
    end

    context "when the ranker is unavailable" do
      it "returns an array of ranks in descending order, to preserve original rank" do
        stub_ranker_is_unavailable
        expect(ranks).to eq([2, 1])
      end
    end
  end
end
