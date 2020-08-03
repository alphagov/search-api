require "spec_helper"

RSpec.describe LearnToRank::DataPipeline::RelevancyJudgements do
  subject(:judgements) do
    described_class.new(queries: queries).relevancy_judgements.force
  end

  let(:queries) do
    {
      "micropig" => [
        { link: "1", rank: 1, views: 100, clicks: 20 },
        { link: "2", rank: 2, views: 100, clicks: 15 },
      ],
      "vehicle tax" => [
        { link: "3", rank: 1, views: 100, clicks: 15 },
        { link: "4", rank: 3, views: 100, clicks: 10 },
        { link: "5", rank: 4, views: 100, clicks: 20 },
        { link: "1", rank: 5, views: 100, clicks: 5 },
        { link: "2", rank: 6, views: 100, clicks: 2 },
      ],
    }
  end

  describe "#relevancy_judgements" do
    context "no queries are provided" do
      let(:queries) { {} }
      it "returns an empty array" do
        expect(judgements).to eq([])
      end
    end

    it "returns an array of relevancy judgements, with scores between 0 and 3" do
      expect(judgements).to eq([
        { link: "1", query: "micropig", score: 3 },
        { link: "2", query: "micropig", score: 2 },
        { link: "3", query: "vehicle tax", score: 2 },
        { link: "4", query: "vehicle tax", score: 2 },
        { link: "5", query: "vehicle tax", score: 3 },
        { link: "1", query: "vehicle tax", score: 1 },
        { link: "2", query: "vehicle tax", score: 1 },
      ])
    end
  end
end
