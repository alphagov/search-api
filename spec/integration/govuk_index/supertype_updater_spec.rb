require "spec_helper"

RSpec.describe GovukIndex::Updater do
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
