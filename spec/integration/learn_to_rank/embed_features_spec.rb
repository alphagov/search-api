require "spec_helper"

RSpec.describe LearnToRank::EmbedFeatures do
  subject(:augmented_judgements) do
    described_class.new(judgements).augmented_judgements
  end
  let(:judgements) do
    [
      { query: "dog", id: "/dog", rank: 3 },
      { query: "dog", id: "/pet", rank: 2 },
      { query: "dog", id: "/whiskers", rank: 1 },
      { query: "dog", id: "/kitten", rank: 0 },
      { query: "dog", id: "/cat", rank: 0 },

      { query: "cat", id: "/cat", rank: 3 },
      { query: "cat", id: "/kitten", rank: 3 },
      { query: "cat", id: "/pet", rank: 2 },
      { query: "cat", id: "/whiskers", rank: 2 },
      { query: "cat", id: "/dog", rank: 0 },
    ]
  end

  describe "#augmented_judgements" do
    context "when no relevancy judgements are provided" do
      let(:judgements) { [] }
      it "returns no judgements" do
        expect(augmented_judgements).to eq([])
      end
    end

    context "when no documents are returned for the queries" do
      it "returns no judgements" do
        expect(augmented_judgements).to eq([])
      end
    end

    context "when documents are in the index" do
      it "returns only queries which have been augmented" do
        %w(pet whiskers kitten cat dog 'cat cat cat!').each { |doc|
          commit_document("government_test",
                          "title" => "#{doc} and cat and dog",
                          "description" => "A story about a cat or dog!",
                          "link" => "/#{doc}",
                          "popularity" => doc.length)
        }

        expect(augmented_judgements).to eq([
          {
            query: "dog",
            id: "/dog",
            rank: 3,
            features: {
              "1" => 3,
              "2" => 5.9035783,
              "3" => 2.01966227,
              "4" => 0.80118835,
              "5" => 0,
              "6" => 0.066765696,
            },
          },
          {
            query: "dog",
            id: "/pet",
            rank: 2,
            features: {
              "1" => 3,
              "2" => 4.7228627,
              "3" => 1.46884529,
              "4" => 0.80118835,
              "5" => 0,
              "6" => 0.066765696,
            },
          },
          {
            query: "dog",
            id: "/whiskers",
            rank: 1,
            features: {
              "1" => 8,
              "2" => 17.192469,
              "3" => 2.00553716,
              "4" => 1.09392936,
              "5" => 0,
              "6" => 0.09116078,
            },
          },
          {
            query: "dog",
            id: "/kitten",
            rank: 0,
            features: {
              "1" => 6,
              "2" => 12.894888,
              "3" => 2.00553716,
              "4" => 1.09392936,
              "5" => 0,
              "6" => 0.09116078,
            },
          },
          {
            query: "dog",
            id: "/cat",
            rank: 0,
            features: {
              "1" => 3,
              "2" => 4.7228627,
              "3" => 1.46884529,
              "4" => 0.80118835,
              "5" => 0,
              "6" => 0.066765696,
            },
          },
          {
            query: "cat",
            id: "/cat",
            rank: 3,
            features: {
              "1" => 3,
              "2" => 5.9035783,
              "3" => 2.01966227,
              "4" => 0.80118835,
              "5" => 0,
              "6" => 0.066765696,
            },
          },
          {
            query: "cat",
            id: "/kitten",
            rank: 3,
            features: {
              "1" => 6,
              "2" => 12.894888,
              "3" => 2.00553716,
              "4" => 1.09392936,
              "5" => 0,
              "6" => 0.09116078,
            },
          },
          {
            query: "cat",
            id: "/pet",
            rank: 2,
            features: {
              "1" => 3,
              "2" => 4.7228627,
              "3" => 1.46884529,
              "4" => 0.80118835,
              "5" => 0,
              "6" => 0.066765696,
            },
          },
          {
            query: "cat",
            id: "/whiskers",
            rank: 2,
            features: {
              "1" => 8,
              "2" => 17.192469,
              "3" => 2.00553716,
              "4" => 1.09392936,
              "5" => 0,
              "6" => 0.09116078,
            },
          },
          {
            query: "cat",
            id: "/dog",
            rank: 0,
            features: {
              "1" => 3,
              "2" => 4.7228627,
              "3" => 1.46884529,
              "4" => 0.80118835,
              "5" => 0,
              "6" => 0.066765696,
            },
          },
        ])
      end
    end
  end
end
