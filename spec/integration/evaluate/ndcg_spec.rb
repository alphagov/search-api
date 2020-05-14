require "spec_helper"

RSpec.describe Evaluate::Ndcg do
  subject(:ndcg) do
    described_class.new(relevancy_judgements, ab_tests).compute_ndcg
  end
  let(:relevancy_judgements) do
    [
      { query: "dog", link: "/dog", score: 3 },
      { query: "dog", link: "/dog-walking-dogs", score: 2 },
      { query: "dog", link: "/dogs", score: 3 },
      { query: "dog", link: "/dog-dog-owner", score: 1 },
      { query: "dog", link: "/cat-owners", score: 0 },
      { query: "dog", link: "/cat", score: 0 },

      { query: "cat", link: "/cat-cat-cat!", score: 2 },
      { query: "cat", link: "/cat-owners", score: 2 },
      { query: "cat", link: "/cats", score: 3 },
      { query: "cat", link: "/cat-dog-owners", score: 1 },
      { query: "cat", link: "/dog", score: 0 },
    ]
  end

  let(:ab_tests) { nil }

  describe "#ndcg" do
    context "when no relevancy judgements are provided" do
      let(:relevancy_judgements) { [] }
      it "returns the default response" do
        expect(ndcg).to eq({ "average_ndcg" => { "1" => 0, "10" => 0, "20" => 0, "3" => 0, "5" => 0 } })
      end
    end

    context "when no documents are returned for the queries" do
      it "returns a zero ndcg score for all queries" do
        expect(ndcg).to eq({
          "average_ndcg" => { "1" => 0, "10" => 0, "20" => 0, "3" => 0, "5" => 0 },
          "cat" => { "1" => 0, "10" => 0, "20" => 0, "3" => 0, "5" => 0 },
          "dog" => { "1" => 0, "10" => 0, "20" => 0, "3" => 0, "5" => 0 },
        })
      end
    end

    context "when documents are in the index" do
      it "returns the ndcg score for all queries" do
        [
          "pet",
          "whiskers",
          "kitten",
          "cat",
          "cats",
          "dogs",
          "animals",
          "cat-owners",
          "dog-owners",
          "dog walking dogs",
          "cat-dog-owners",
          "pets",
          "kittens",
          "whiskers",
          "dog dog owner",
          "dogs",
          "terriers",
          "corgies",
          "alsatians",
          "dogg",
          "cat cat cat!",
        ].each do |doc|
          commit_document(
            "government_test",
            "title" => doc,
            "description" => "A document about #{doc} for #{doc}s.",
            "link" => "/#{doc.split(' ').join('-')}",
          )
        end

        expect(ndcg).to eq({
          "average_ndcg" => { "1" => 1.0, "10" => 0.8105205226122176, "20" => 0.8105205226122176, "3" => 0.8010100946003349, "5" => 0.8105205226122176 },
          "cat" => { "1" => 1.0, "10" => 0.7782127803434975, "20" => 0.7782127803434975, "3" => 0.7591919243197319, "5" => 0.7782127803434975 },
          "dog" => { "1" => 1.0, "10" => 0.8428282648809379, "20" => 0.8428282648809379, "3" => 0.8428282648809379, "5" => 0.8428282648809379 },
        })
      end
    end
  end
end
