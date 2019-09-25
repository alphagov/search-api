require "spec_helper"

RSpec.describe "GovukIndex::SyncDataTest" do
  before do
    allow(GovukIndex::MigratedFormats).to receive(:indexable_formats).and_return("help_page" => :all)
  end

  it "syncs records for non indexable formats" do
    commit_document("government_test", { link: "/test", popularity: 0.3, format: "edition" }, id: "/test", type: "edition")

    GovukIndex::SyncUpdater.update(source_index: "government_test", destination_index: "govuk_test")

    expect_document_is_in_rummager({ "link" => "/test" }, type: "edition", index: "govuk_test")
  end

  it "syncs will overwrite existing data" do
    insert_document("government_test", { link: "/test", popularity: 0.3, format: "edition" }, id: "/test", type: "edition")
    commit_index("government_test")
    insert_document("govuk_test", { link: "/test", popularity: 0.4, format: "edition" }, id: "/test", type: "edition")
    commit_index("govuk_test")

    GovukIndex::SyncUpdater.update(source_index: "government_test", destination_index: "govuk_test")

    expect_document_is_in_rummager({ "link" => "/test", "popularity" => 0.3 }, type: "edition", index: "govuk_test")
  end

  it "will not syncs records for indexable formats" do
    insert_document("government_test", { link: "/test", popularity: 0.3, format: "help_page" }, id: "/test", type: "edition")
    commit_index("government_test")
    insert_document("govuk_test", { link: "/test", popularity: 0.4, format: "help_page" }, id: "/test", type: "edition")
    commit_index("govuk_test")

    GovukIndex::SyncUpdater.update(source_index: "government_test", destination_index: "govuk_test")

    expect_document_is_in_rummager({ "link" => "/test", "popularity" => 0.4 }, type: "edition", index: "govuk_test")
  end
end
