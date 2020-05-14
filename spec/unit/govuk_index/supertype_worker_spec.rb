require "spec_helper"

RSpec.describe GovukIndex::SupertypeWorker do
  subject(:worker) { described_class.new }

  before do
    allow(GovukDocumentTypes).to receive(:supertypes)
      .with(document_type: "testgroup")
      .and_return("supertype1" => "type1", "supertype2" => "type2")
    @processor = instance_double("processor", save: nil, commit: nil)
    allow(Index::ElasticsearchProcessor).to receive(:new).and_return(@processor)
  end

  it "saves all records" do
    records = [
      { "identifier" => { "_id" => "record_1" }, "document" => { "content_store_document_type" => "testgroup" } },
      { "identifier" => { "_id" => "record_2" }, "document" => { "content_store_document_type" => "testgroup" } },
    ]
    worker.perform(records, "govuk_test")

    expect(@processor).to have_received(:save).twice
    expect(@processor).to have_received(:commit)
  end

  it "updates supertype fields" do
    record = { "identifier" => { "_id" => "record_1" },
               "document" => { "title" => "test_doc", "content_store_document_type" => "testgroup" } }
    worker.perform([record], "govuk_test")

    expect(@processor).to have_received(:save).with(
      having_attributes(
        document: hash_including({ "supertype1" => "type1", "supertype2" => "type2", "title" => "test_doc" }),
      ),
    )
  end

  it "does not save if the supertype fields do not need to be updated" do
    record = { "identifier" => { "_id" => "record_1" },
               "document" => { "title" => "test_doc",
                               "content_store_document_type" => "testgroup",
                               "supertype1" => "type1",
                               "supertype2" => "type2" } }
    worker.perform([record], "govuk_test")

    expect(@processor).not_to have_received(:save)
  end
end
