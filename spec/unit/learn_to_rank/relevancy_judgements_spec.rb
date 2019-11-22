require "spec_helper"

RSpec.describe LearnToRank::RelevancyJudgements do
  subject(:judgements) do
    described_class.new(queries: queries).relevancy_judgements
  end

  let(:queries) {
    {
      "micropig" => [
        { content_id: "1", rank: 1, views: 100, clicks: 20 },
        { content_id: "2", rank: 2, views: 100, clicks: 15 },
      ],
      "vehicle tax" => [
        { content_id: "3", rank: 1, views: 100, clicks: 15 },
        { content_id: "4", rank: 3, views: 100, clicks: 10 },
        { content_id: "5", rank: 4, views: 100, clicks: 20 },
        { content_id: "1", rank: 5, views: 100, clicks: 5 },
        { content_id: "2", rank: 6, views: 100, clicks: 2 },
      ],
    }
  }

  describe "#relevancy_judgements" do
    context "no queries are provided" do
      let(:queries) { {} }
      it "returns an empty array" do
        expect(judgements).to eq([])
      end
    end

    it "returns an array of relevancy judgements, with scores between 0 and 3" do
      expect(judgements).to eq([
        { content_id: "1", query: "micropig", score: 3 },
        { content_id: "2", query: "micropig", score: 2 },
        { content_id: "3", query: "vehicle tax", score: 2 },
        { content_id: "4", query: "vehicle tax", score: 2 },
        { content_id: "5", query: "vehicle tax", score: 3 },
        { content_id: "1", query: "vehicle tax", score: 1 },
        { content_id: "2", query: "vehicle tax", score: 1 },
      ])
    end
  end
end
