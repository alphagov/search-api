require "spec_helper"

RSpec.describe LearnToRank::FeatureSets do
  include Fixtures::LearnToRankExplain

  subject(:feature_sets) { described_class.new.call(query, search_results) }
  let(:query) { "harry potter" }

  describe "#call" do
    context "with no query or results" do
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
          "_source" => {
            "popularity" => 10,
            "title" => "Harry Poter",
            "description" => "Harry Potter is a wizard",
            "link" => "/harry-potter",
            "public_timestamp" => "2019-11-12T17:16:01.000+01:00",
            "format" => "person",
            "organisation_content_ids" => %w[6667cce2-e809-4e21-ae09-cb0bdc1ddda3],
            "updated_at" => "2019-11-12T17:16:01.000+01:00",
            "indexable_content" => "Harry Potter is a wizard",
          },
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
          "7" => 11.0,
          "8" => 24.0,
          "9" => 13.0,
          "10" => 1_573_516_800.0,
          "11" => 12.0,
          "12" => 1.0,
          "13" => 12.0,
          "14" => 24.0,
          "15" => 1.0,
          "16" => 1_573_516_800.0,
        }])
      end
    end
  end
end
