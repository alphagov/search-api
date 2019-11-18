require "spec_helper"

RSpec.describe Evaluate::Ndcg do
  subject(:ndcg) do
    described_class.new(relevancy_judgements, ab_tests).compute_ndcg
  end
  let(:relevancy_judgements) do
    [
      { query: "dog", id: "/dog", rank: 3 },
      { query: "dog", id: "/pet", rank: 2 },
      { query: "dog", id: "/whiskers", rank: 1 },
      { query: "dog", id: "/kitten", rank: 0 },
      { query: "dog", id: "/cat", rank: 0 },
      { query: "dog", id: "/cat", rank: 0 },

      { query: "cat", id: "/cat", rank: 3 },
      { query: "cat", id: "/kitten", rank: 3 },
      { query: "cat", id: "/pet", rank: 2 },
      { query: "cat", id: "/whiskers", rank: 2 },
      { query: "cat", id: "/dog", rank: 0 },
    ]
  end

  let(:ab_tests) { nil }

  describe "#ndcg" do
    context "when no relevancy judgements are provided" do
      let(:relevancy_judgements) { [] }
      it "returns the default response" do
        expect(ndcg).to eq({ "average_ndcg" => 0 })
      end
    end

    context "when no documents are returned for the queries" do
      it "returns a zero ndcg score for all queries" do
        expect(ndcg).to eq({
          "average_ndcg" => 0,
          "cat"          => 0,
          "dog"          => 0,
        })
      end
    end

    context "when documents are in the index" do
      it "returns the ndcg score for all queries" do
        %w(
          pet whiskers kitten cat cats dogs animals
          cat-owners dog-owners dog cat-dog-owners
          pets kittens whiskers 'dog dog owner' dogs terriers
          corgies alsatians dogg 'cat cat cat!'
        ).each { |doc|
          commit_document("government_test",
                          "title" => doc,
                          "description" => "A document about #{doc} for #{doc}s.",
                          "link" => "/#{doc}")
        }

        expect(ndcg).to eq({
          "average_ndcg" => 0.46533827903669656,
          "cat"          => 0.5,
          "dog"          => 0.43067655807339306,
        })
      end
    end
  end
end
