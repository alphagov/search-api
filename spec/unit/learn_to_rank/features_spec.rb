require "spec_helper"

RSpec.describe LearnToRank::Features do
  include Fixtures::LearnToRankExplain

  describe "#as_hash" do
    context "with no arguments" do
      subject(:features) { described_class.new }
      it "returns default feature values" do
        expect(features.as_hash).to eq(
          "1" => 0.0,
          "2" => 0.0,
          "3" => 0.0,
          "4" => 0.0,
          "5" => 0.0,
          "6" => 0.0,
        )
      end
    end

    context "when arguments are provided" do
      subject(:features) {
        described_class.new(
          popularity: 10,
          es_score: 0.123456789,
          explain: default_explanation,
        )
      }

      it "returns a hash of features with the correct keys" do
        expect(features.as_hash).to eq(
          "1" => 10.0,
          "2" => 0.123456789,
          "3" => 125.71911880000002,
          "4" => 61.249814,
          "5" => 33.8111188,
          "6" => 5.6863167,
        )
      end
    end
  end
end
