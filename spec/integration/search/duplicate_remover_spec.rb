require "spec_helper"

RSpec.describe Search::DuplicateRemover do
  let(:index) { "government_test" }
  let(:io) { StringIO.new }
  let(:logger) { Logger.new(io) }
  let(:duplicates) { Search::DuplicateFinder.new(index:).find_duplicates }
  subject(:remover) { described_class.new(index:, logger:) }

  context "A set of duplicate documents has no updated_at field" do
    before :each do
      commit_document(index, { link: "link/path_a", content_id: "same", title: "title_a" })
      commit_document(index, { link: "link/path_b", content_id: "same", title: "title_b" })
      remover.remove_duplicates(duplicates:)
    end
    it "does not delete them because it is unknown which one is the most recent" do
      expect_document_is_in_rummager({ "link" => "link/path_a" }, index:)
      expect_document_is_in_rummager({ "link" => "link/path_b" }, index:)
    end
    it "logs the occurrence of the duplicate document without updated_at field" do
      expect(io.string).to include("None of the documents with content_item: same have an 'updated_at' field.")
    end
  end

  context "There are two duplicate documents; one with and one without an updated_at field" do
    it "deletes the duplicate document without an updated_at field" do
      commit_document(index, { link: "link/path_a", content_id: "same", updated_at: Time.utc(2024, 1, 1) })
      commit_document(index, { link: "link/path_b", content_id: "same" })
      remover.remove_duplicates(duplicates:)

      expect_document_is_in_rummager({ "link" => "link/path_a" }, index:)
      expect_document_missing_in_rummager(id: "link/path_b", index:)
    end
  end
  context "There are multiple duplicate documents; all have an updated_at field" do
    it "keeps the most recent document and deletes the others" do
      commit_document(index, { link: "link/path_a", content_id: "same", updated_at: Time.utc(2024, 1, 1) })
      commit_document(index, { link: "link/path_b", content_id: "same", updated_at: Time.utc(2025, 1, 1) })
      commit_document(index, { link: "link/path_c", content_id: "same", updated_at: Time.utc(2023, 1, 1) })
      remover.remove_duplicates(duplicates:)

      expect_document_is_in_rummager({ "link" => "link/path_b" }, index:)
      expect_document_missing_in_rummager(id: "link/path_a", index:)
      expect_document_missing_in_rummager(id: "link/path_c", index:)
    end
  end

  context "There are several groups of duplicates" do
    before :each do
      commit_document(index, { link: "link/path_a", content_id: "same", updated_at: Time.utc(2024, 1, 1) })
      commit_document(index, { link: "link/path_b", content_id: "same" })
      commit_document(index, { link: "link/path_c", content_id: "other", updated_at: Time.utc(2024, 1, 1) })
      commit_document(index, { link: "link/path_d", content_id: "other", updated_at: Time.utc(2023, 1, 1) })

      remover.remove_duplicates(duplicates:)
    end
    it "deletes duplicates from each group, keeping the most recent ones" do
      expect_document_is_in_rummager({ "link" => "link/path_a" }, index:)
      expect_document_missing_in_rummager(id: "link/path_b", index:)
      expect_document_is_in_rummager({ "link" => "link/path_c" }, index:)
      expect_document_missing_in_rummager(id: "link/path_d", index:)
    end
    it "logs the duplicates that were deleted" do
      logged_output = io.string
      expect(logged_output).to include("Deleted duplicate document: link/path_b")
      expect(logged_output).to include("Deleted duplicate document: link/path_d")
    end
  end
end
