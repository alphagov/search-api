require "spec_helper"

RSpec.describe Search::DuplicateFinder do
  let(:index) { "government_test" }
  describe "there are no documents in Elasticsearch" do
    it "returns an empty array" do
      expect(Search::DuplicateFinder.new(index:).find_duplicates).to eq([])
    end
  end
  describe "there are documents in Elasticsearch, none have a duplicate content_id" do
    it "returns an empty array" do
      (1..10).each do |n|
        commit_document(index, { link: "link/path#{n}", content_id: SecureRandom.uuid })
      end
      expect(Search::DuplicateFinder.new(index:).find_duplicates).to be_empty
    end
  end
  describe "there are documents in Elasticsearch, some have a duplicate content_id" do
    it "returns an array of duplicate content_ids" do
      (1..10).each do |n|
        commit_document(index, { link: "link/path#{n}", content_id: SecureRandom.uuid })
      end
      date_1 = Time.utc(2024, 1, 1)
      date_2 = Time.utc(2025, 2, 2)
      commit_document(index, { link: "link/path_a", content_id: "same", title: "title_a", updated_at: date_1 })
      commit_document(index, { link: "link/path_b", content_id: "same", title: "title_b" })
      commit_document(index, { link: "link/path_c", content_id: "other", title: "title_c", updated_at: date_2 })
      commit_document(index, { link: "link/path_d", content_id: "other", title: "title_d" })

      result = Search::DuplicateFinder.new(index:).find_duplicates

      expect(result).to match_array([
        a_hash_including(
          content_id: "same",
          documents: match_array([
            { "title" => "title_a", "link" => "link/path_a", "updated_at" => date_1 },
            { "title" => "title_b", "link" => "link/path_b" },
          ]),
        ),
        a_hash_including(
          content_id: "other",
          documents: match_array([
            { "title" => "title_c", "link" => "link/path_c", "updated_at" => date_2 },
            { "title" => "title_d", "link" => "link/path_d" },
          ]),
        ),
      ])
    end
  end
end
