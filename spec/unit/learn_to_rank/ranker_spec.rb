require "spec_helper"

RSpec.describe LearnToRank::Ranker do
  include Fixtures::LearnToRankExplain

  let(:ranks) { described_class.new(feature_sets).ranks }

  let(:feature_sets) do
    LearnToRank::FeatureSets.new.call(search_results)
  end

  let(:search_results) do
    [
      {
        "_explanation" => default_explanation,
        "_score" => 0.98,
        "_source" => { "popularity" => 10 },
      },
      {
        "_explanation" => default_explanation,
        "_score" => 0.97,
        "_source" => { "popularity" => 5 },
      },
    ]
  end

  describe "#ranks" do
    context "when there are no search results" do
      let(:search_results) { [] }
      it "returns an empty array without calling ranker" do
        expect(ranks).to eq([])
      end
    end

    context "when there are search results" do
      let(:ranker_response) do
        [1, 2]
      end

      it "returns an array of new ranks" do
        stub_request_to_ranker(feature_sets, ranker_response)
        expect(ranks).to eq(ranker_response)
      end
    end

    context "when the ranker is unavailable" do
      it "returns an array of ranks in descending order, to preserve original rank" do
        stub_ranker_is_unavailable
        expect(ranks).to eq([2, 1])
      end
    end
  end

  def stub_request_to_ranker(examples, rank_response)
    stub_request(:post, "http://reranker:8501/v1/models/ltr:regress")
      .with(
        body: {
          signature_name: "regression",
          examples: examples,
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
        },
      )
      .to_return(status: 200, body: { "results" => rank_response }.to_json)
  end

  def stub_ranker_is_unavailable
    stub_request(:post, "http://reranker:8501/v1/models/ltr:regress")
      .to_return(status: 500)
  end
end
