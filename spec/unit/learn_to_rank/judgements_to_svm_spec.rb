require "spec_helper"

RSpec.describe LearnToRank::JudgementsToSvm do
  subject(:formatted) { described_class.new(judgements).svm_format }

  describe "#svm_format" do
    context "when an empty set is provided" do
      let(:judgements) { [] }
      it "returns an empty array" do
        expect(formatted).to eq([])
      end
    end

    context "when judgements are provided" do
      let(:judgements) do
        [
          { query: "tax", rank: 2, features: { "1": 2, "2": 0.1, "3": 10 } },
          { query: "tax", rank: 0, features: { "1": 2, "2": 0.1, "3": 20 } },
          { query: "cat", rank: 3, features: { "2": 2, "3": 0.2, "2": 90 } },
          { query: "sat", rank: 2, features: { "1": 2, "3": 0.1, "2": 10 } },
          { query: "mat", rank: 3, features: { "2": 2, "1": 0.1, "3": 10 } },
          { query: "mat", rank: 1, features: { "1": 2, "2": 0.1, "3": 0 } },
          { query: "hat", rank: 0, features: { "1": 2, "2": 0.1, "3": 0 } },
        ]
      end
      it "returns an array of SVM formatted data" do
        expect(formatted).to eq([
          "2 qid:1 1:2 2:0.1 3:10",
          "0 qid:1 1:2 2:0.1 3:20",
          "3 qid:2 1:0 2:90 3:0.2",
          "2 qid:3 1:2 2:10 3:0.1",
          "3 qid:4 1:0.1 2:2 3:10",
          "1 qid:4 1:2 2:0.1 3:0",
          "0 qid:5 1:2 2:0.1 3:0",
        ])
      end
    end
  end
end
