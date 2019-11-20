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
          "7" => 0.0,
          "8" => 0.0,
          "9" => 0.0,
          "10" => 0.0,
          "11" => 0.0,
          "12" => 0.0,
          "13" => 0.0,
          "14" => 0.0,
          "15" => 0.0,
          "16" => 0.0,
        )
      end
    end

    context "when arguments are provided" do
      subject(:features) {
        described_class.new(
          popularity: 10,
          es_score: 0.123456789,
          explain: default_explanation,
          title: "Harry Potter",
          description: "Harry Potter was a wizard",
          link: "/harry-potter",
          public_timestamp: "2018-10-12T17:16:01.000+01:00",
          format: "document_collection",
          organisation_content_ids: %w[f323e83c-868b-4bcb-b6e2-a8f9bb40397e],
          indexable_content: "A short piece of content",
          query: "who is harry potter",
          updated_at: "2019-11-12T17:16:01.000+01:00"
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
          "7" => 12.0,
          "8" => 25.0,
          "9" => 13.0,
          "10" => 1539302400.0,
          "11" => 11.0,
          "12" => 90.0,
          "13" => 19.0,
          "14" => 24.0,
          "15" => 1.0,
          "16" => 1573516800.0,
        )
      end
    end
  end
end
