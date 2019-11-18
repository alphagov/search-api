require "spec_helper"

RSpec.describe LearnToRank::FeatureSets do
  include Fixtures::LearnToRankExplain

  subject(:feature_sets) { described_class.new.call(search_results) }

  describe "#call" do
    context "with no results" do
      let(:search_results) { [] }

      it "returns an empty array" do
        expect(feature_sets).to eq([])
      end
    end

    context "when there are results" do
      let(:search_results) do
        [{
          "_explanation" => default_explanation,
          "_score" => 0.123456789,
          "_source" => { "popularity" => 10 },
        }]
      end

      it "returns an array of feature hashes" do
        expect(feature_sets).to eq([{
          "1" => 10.0,
          "2" => 0.123456789,
          "3" => 125.71911880000002,
          "4" => 61.249814,
          "5" => 33.8111188,
          "6" => 5.6863167,
        }])
      end
    end
  end
end
