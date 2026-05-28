require "spec_helper"

RSpec.describe "GovukIndex::SwitchOnFormatsInGovukIndexTest" do
  let(:index_name) { SearchConfig.govuk_index_name }
  before do
    commit_document(index_name, build(:document, :all, title: "govuk answer", format: "answer"))
    commit_document(index_name, build(:document, :all, title: "govuk help", format: "help_page"))
  end

  it "defaults to excluding govuk index records" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return({})

    get "/search"

    expect(parsed_response["results"].map { |r| r["title"] }.sort).to be_empty
  end

  it "can enable format to use govuk index" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return("help_page" => :all)

    get "/search"

    expect(parsed_response["results"].map { |r| r["title"] }.sort).to eq(["govuk help"])
  end

  it "can enable multiple formats to use govuk index" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return("help_page" => :all, "answer" => :all)

    get "/search"

    expect(parsed_response["results"].map { |r| r["title"] }.sort).to eq(["govuk answer", "govuk help"])
  end
end
