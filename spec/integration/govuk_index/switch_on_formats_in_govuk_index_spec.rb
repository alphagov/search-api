require "spec_helper"

RSpec.describe "GovukIndex::SwitchOnFormatsInGovukIndexTest" do
  before do
    insert_document("government_test", { title: "government answer", link: "/government/answer", format: "answer" })
    insert_document("government_test", { title: "government help", link: "/government/help", format: "help_page" })
    commit_index("government_test")
    insert_document("govuk_test", { title: "govuk answer", link: "/govuk/answer", format: "answer" })
    insert_document("govuk_test", { title: "govuk help", link: "/govuk/help", format: "help_page" })
    commit_index("govuk_test")
  end

  it "defaults to excluding govuk index records" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return({})

    get "/search"

    expect(parsed_response["results"].map { |r| r["title"] }.sort).to eq(["government answer", "government help"])
  end

  it "can enable format to use govuk index" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return("help_page" => :all)

    get "/search"

    expect(parsed_response["results"].map { |r| r["title"] }.sort).to eq(["government answer", "govuk help"])
  end

  it "can enable multiple formats to use govuk index" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return("help_page" => :all, "answer" => :all)

    get "/search"

    expect(parsed_response["results"].map { |r| r["title"] }.sort).to eq(["govuk answer", "govuk help"])
  end
end
