require "spec_helper"

RSpec.describe LearnToRank::DataPipeline::EmbedFeatures do
  subject(:augmented_judgements) do
    described_class.new(judgements).augmented_judgements.force
  end
  let(:judgements) do
    [
      { query: "dog", link: "/dog", score: 3 },
      { query: "dog", link: "/pet", score: 2 },
      { query: "dog", link: "/whiskers", score: 1 },
      { query: "dog", link: "/kitten", score: 0 },
      { query: "dog", link: "/cat", score: 0 },

      { query: "cat", link: "/cat", score: 3 },
      { query: "cat", link: "/kitten", score: 3 },
      { query: "cat", link: "/pet", score: 2 },
      { query: "cat", link: "/whiskers", score: 2 },
      { query: "cat", link: "/dog", score: 0 },
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
                          "popularity" => doc.length,
                          "public_timestamp" => "2019-11-12T17:16:01.000+01:00",
                          "format" => "case_study",
                          "organisation_content_ids" => %w[de4e9dc6-cca4-43af-a594-682023b84d6c],
                          "query" => "dogs or cats",
                          "updated_at" => "2019-11-12T17:16:01.000+01:00",
                          "indexable_content" => "Story about dogs and/or cats")
        }

        expect(augmented_judgements).to eq([
          {
            query: "dog",
            link: "/dog",
            score: 3,
            features: {
              "1" => 3.0,
              "2" => 7.8356586,
              "3" => 2.01966227,
              "4" => 0.80118835,
              "5" => 0.40059416999999997,
              "6" => 0.091802835,
              "7" => 19.0,
              "8" => 27.0,
              "9" => 4.0,
              "10" => 1573516800.0,
              "11" => 13.0,
              "12" => 9.0,
              "13" => 3.0,
              "14" => 28.0,
              "15" => 1.0,
              "16" => 1573516800.0,
            },
          },
          {
            query: "dog",
            link: "/pet",
            score: 2,
            features: {
              "1" => 3.0,
              "2" => 6.418799,
              "3" => 1.46884529,
              "4" => 0.80118835,
              "5" => 0.40059416999999997,
              "6" => 0.091802835,
              "7" => 19.0,
              "8" => 27.0,
              "9" => 4.0,
              "10" => 1573516800.0,
              "11" => 13.0,
              "12" => 9.0,
              "13" => 3.0,
              "14" => 28.0,
              "15" => 1.0,
              "16" => 1573516800.0,
            },
          },
          {
            query: "dog",
            link: "/whiskers",
            score: 1,
            features: {
              "1" => 8.0,
              "2" => 23.366127,
              "3" => 2.00553716,
              "4" => 1.09392936,
              "5" => 0.54696469,
              "6" => 0.12534608,
              "7" => 24.0,
              "8" => 27.0,
              "9" => 9.0,
              "10" => 1573516800.0,
              "11" => 13.0,
              "12" => 9.0,
              "13" => 3.0,
              "14" => 28.0,
              "15" => 1.0,
              "16" => 1573516800.0,
            },
          },
          { query: "dog",
           link: "/kitten",
           score: 0,
           features: {
             "1" => 6.0,
             "2" => 17.525326,
             "3" => 2.00553716,
             "4" => 1.09392936,
             "5" => 0.54696469,
             "6" => 0.12534608,
             "7" => 22.0,
             "8" => 27.0,
             "9" => 7.0,
             "10" => 1573516800.0,
             "11" => 13.0,
             "12" => 9.0,
             "13" => 3.0,
             "14" => 28.0,
             "15" => 1.0,
             "16" => 1573516800.0,
           } },
          {
            query: "dog",
            link: "/cat",
            score: 0,
            features: {
              "1" => 3.0,
              "2" => 6.418799,
              "3" => 1.46884529,
              "4" => 0.80118835,
              "5" => 0.40059416999999997,
              "6" => 0.091802835,
              "7" => 19.0,
              "8" => 27.0,
              "9" => 4.0,
              "10" => 1573516800.0,
              "11" => 13.0,
              "12" => 9.0,
              "13" => 3.0,
              "14" => 28.0,
              "15" => 1.0,
              "16" => 1573516800.0,
            },
          },
          {
            query: "cat",
            link: "/cat",
            score: 3,
            features: {
              "1" => 3.0,
              "2" => 7.8356586,
              "3" => 2.01966227,
              "4" => 0.80118835,
              "5" => 0.40059416999999997,
              "6" => 0.091802835,
              "7" => 19.0,
              "8" => 27.0,
              "9" => 4.0,
              "10" => 1573516800.0,
              "11" => 13.0,
              "12" => 9.0,
              "13" => 3.0,
              "14" => 28.0,
              "15" => 1.0,
              "16" => 1573516800.0,
              },
            },
          {
            query: "cat",
            link: "/kitten",
            score: 3,
            features: {
              "1" => 6.0,
              "2" => 17.525326,
              "3" => 2.00553716,
              "4" => 1.09392936,
              "5" => 0.54696469,
              "6" => 0.12534608,
              "7" => 22.0,
              "8" => 27.0,
              "9" => 7.0,
              "10" => 1573516800.0,
              "11" => 13.0,
              "12" => 9.0,
              "13" => 3.0,
              "14" => 28.0,
              "15" => 1.0,
              "16" => 1573516800.0,
            },
          },
          {
            query: "cat",
            link: "/pet",
            score: 2,
            features: {
              "1" => 3.0,
              "2" => 6.418799,
              "3" => 1.46884529,
              "4" => 0.80118835,
              "5" => 0.40059416999999997,
              "6" => 0.091802835,
              "7" => 19.0,
              "8" => 27.0,
              "9" => 4.0,
              "10" => 1573516800.0,
              "11" => 13.0,
              "12" => 9.0,
              "13" => 3.0,
              "14" => 28.0,
              "15" => 1.0,
              "16" => 1573516800.0,
            },
          },
          {
           query: "cat",
           link: "/whiskers",
           score: 2,
           features: {
             "1" => 8.0,
             "2" => 23.366127,
             "3" => 2.00553716,
             "4" => 1.09392936,
             "5" => 0.54696469,
             "6" => 0.12534608,
             "7" => 24.0,
             "8" => 27.0,
             "9" => 9.0,
             "10" => 1573516800.0,
             "11" => 13.0,
             "12" => 9.0,
             "13" => 3.0,
             "14" => 28.0,
             "15" => 1.0,
             "16" => 1573516800.0,
            },
          },
          {
            query: "cat",
            link: "/dog",
            score: 0,
            features: {
              "1" => 3.0,
              "2" => 6.418799,
              "3" => 1.46884529,
              "4" => 0.80118835,
              "5" => 0.40059416999999997,
              "6" => 0.091802835,
              "7" => 19.0,
              "8" => 27.0,
              "9" => 4.0,
              "10" => 1573516800.0,
              "11" => 13.0,
              "12" => 9.0,
              "13" => 3.0,
              "14" => 28.0,
              "15" => 1.0,
              "16" => 1573516800.0,
            },
          },
        ])
      end
    end
  end
end
