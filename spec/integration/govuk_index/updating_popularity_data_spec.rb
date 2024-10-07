require "spec_helper"

RSpec.describe "GovukIndex::UpdatingPopularityDataTest" do
  before do
    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("help_page" => :all)
  end

  it "updates the popularity when it exists" do
    id = insert_document("govuk_test", { title: "govuk_test_doc", popularity: 0.222, format: "help_page" }, type: "edition")
    commit_index("govuk_test")

    document_count = 4
    document_rank = 2
    insert_document("page-traffic_test", { rank_14: document_rank, path_components: [id, "/test"] }, id:, type: "page-traffic")
    setup_page_traffic_data(document_count:)

    popularity = 1.0 / ([document_rank, document_count].min + SearchConfig.popularity_rank_offset)

    GovukIndex::PopularityUpdater.update("govuk_test")

    expect_document_is_in_rummager({ "link" => id, "popularity" => popularity }, type: "edition", index: "govuk_test")
  end

  it "set the popularity to the lowest popularity when it doesnt exist" do
    id = insert_document("govuk_test", { title: "govuk_test_doc", popularity: 0.222, format: "help_page" }, type: "edition")
    commit_index("govuk_test")

    document_count = 4
    setup_page_traffic_data(document_count:)

    popularity = 1.0 / (document_count + SearchConfig.popularity_rank_offset)

    GovukIndex::PopularityUpdater.update("govuk_test")

    expect_document_is_in_rummager({ "link" => id, "popularity" => popularity }, type: "edition", index: "govuk_test")
  end

  it "ignores popularity update if version has moved on" do
    id = insert_document("govuk_test", { title: "govuk_test_doc", popularity: 0.222, format: "help_page" }, type: "edition", version: 2)
    commit_index("govuk_test")

    document_count = 4
    setup_page_traffic_data(document_count:)

    allow(ScrollEnumerator).to receive(:new).and_return([
      {
        "identifier" => { "_id" => id, "_version" => 1 },
        "document" => { "link" => id, "popularity" => 0.222 },
      },
    ])

    GovukIndex::PopularityUpdater.update("govuk_test")

    expect_document_is_in_rummager({ "link" => id, "popularity" => 0.222 }, type: "edition", index: "govuk_test")
  end

  it "copies version information" do
    id = insert_document("govuk_test", { title: "govuk_test_doc", popularity: 0.222, format: "help_page" }, type: "edition", version: 3)
    commit_index("govuk_test")
    GovukIndex::PopularityUpdater.update("govuk_test")

    document = fetch_document_from_rummager(id:, index: "govuk_test")
    expect(document["_version"]).to eq(3)
  end

  it "skips non indexable formats" do
    id = insert_document("govuk_test", { popularity: 0.222, format: "edition" }, type: "edition", version: 3)
    commit_index("govuk_test")
    GovukIndex::PopularityUpdater.update("govuk_test")

    document = fetch_document_from_rummager(id:, index: "govuk_test")
    expect(0.222).to eq(document["_source"]["popularity"])
  end

  it "does not skips non indexable formats if process all flag is set" do
    id = insert_document("govuk_test", { title: "govuk_test_doc", popularity: 0.222, format: "edition" }, type: "edition", version: 3)
    commit_index("govuk_test")

    document_count = 4
    setup_page_traffic_data(document_count:)

    GovukIndex::PopularityUpdater.update("govuk_test", process_all: true)
    popularity = 1.0 / (document_count + SearchConfig.popularity_rank_offset)

    document = fetch_document_from_rummager(id:, index: "govuk_test")
    expect(popularity).to eq(document["_source"]["popularity"])
  end
end
