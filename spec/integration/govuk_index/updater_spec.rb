require "spec_helper"

RSpec.describe GovukIndex::Updater do
  describe "supertype updates" do
    let(:index) { "govuk_test" }

    before do
      allow(GovukDocumentTypes).to receive(:supertypes)
                                     .with(document_type: "testgroup")
                                     .and_return("supertype1" => "type1", "supertype2" => "type2")
    end

    it "calls the SupertypeJob for all documents in the index" do
      commit_document(index, { link: "link/path", content_store_document_type: "testgroup" })

      GovukIndex::Updater.update(index, GovukIndex::SupertypeJob)
      expect_document_is_in_rummager({ "link" => "link/path", "supertype1" => "type1", "supertype2" => "type2" }, index:)
    end
  end

  describe "popularity updates" do
    let(:initial_popularity) { 0.222 }
    before do
      allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("help_page" => :all)
    end

    it "updates the popularity when it exists" do
      id = insert_document("govuk_test", { title: "govuk_test_doc", popularity: initial_popularity, format: "help_page" }, type: "edition")
      commit_index("govuk_test")

      document_count = 4
      document_rank = 2
      insert_document("page-traffic_test", { rank_14: document_rank, path_components: [id, "/test"] }, id:, type: "page-traffic")
      setup_page_traffic_data(document_count:)

      popularity = 1.0 / ([document_rank, document_count].min + SearchConfig.popularity_rank_offset)

      GovukIndex::Updater.update("govuk_test", GovukIndex::PopularityJob)

      expect(popularity).not_to eq(initial_popularity)
      expect_document_is_in_rummager({ "link" => id, "popularity" => popularity }, type: "edition", index: "govuk_test")
    end

    it "set the popularity to the lowest popularity when it doesnt exist" do
      id = insert_document("govuk_test", { title: "govuk_test_doc", popularity: initial_popularity, format: "help_page" }, type: "edition")
      commit_index("govuk_test")

      document_count = 4
      setup_page_traffic_data(document_count:)

      popularity = 1.0 / (document_count + SearchConfig.popularity_rank_offset)

      GovukIndex::Updater.update("govuk_test", GovukIndex::PopularityJob)

      expect(popularity).not_to eq(initial_popularity)
      expect_document_is_in_rummager({ "link" => id, "popularity" => popularity }, type: "edition", index: "govuk_test")
    end

    it "ignores documents that aren't in the index" do
      id = "test_id"

      allow(ScrollEnumerator).to receive(:new).and_return([id])
      allow(Sidekiq.logger).to receive(:warn)
      processor = instance_double("Index::ElasticsearchProcessor", commit: nil, save: nil)
      allow(Index::ElasticsearchProcessor).to receive(:new).and_return(processor)

      GovukIndex::Updater.update("govuk_test", GovukIndex::PopularityJob)

      expect(Sidekiq.logger)
        .to have_received(:warn).with("Skipping #{id} as it is not in the index")
      expect(processor).not_to have_received(:save)
    end

    it "copies version information" do
      id = insert_document("govuk_test", { title: "govuk_test_doc", popularity: initial_popularity, format: "help_page" }, type: "edition", version: 3)
      commit_index("govuk_test")
      GovukIndex::Updater.update("govuk_test", GovukIndex::PopularityJob)

      document = fetch_document_from_rummager(id:, index: "govuk_test")
      expect(document["_version"]).to eq(3)
    end
  end
end
