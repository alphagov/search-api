require "spec_helper"

RSpec.describe GovukIndex::SupertypeJob do
  subject(:job) { described_class.new }
  let(:index) { instance_double("index") }

  before do
    allow(GovukDocumentTypes).to receive(:supertypes)
      .with(document_type: "testgroup")
      .and_return("supertype1" => "type1", "supertype2" => "type2")
    @processor = instance_double("processor", save: nil, commit: nil)
    allow(Index::ElasticsearchProcessor).to receive(:new).and_return(@processor)
    allow(IndexFinder).to receive(:by_name).and_return(index)
  end

  it "saves all documents" do
    documents = [
      { "_id" => "document_1", "_source" => { "content_store_document_type" => "testgroup" } },
      { "_id" => "document_2", "_source" => { "content_store_document_type" => "testgroup" } },
    ]
    stub_document_lookups(documents)

    document_ids = documents.map { |document| document["_id"] }
    job.perform(document_ids, "govuk_test")

    expect(@processor).to have_received(:save).twice
    expect(@processor).to have_received(:commit)
  end

  it "updates supertype fields" do
    document = { "_id" => "document_1", "_source" => { "title" => "test_doc", "content_store_document_type" => "testgroup" } }
    stub_document_lookups([document])
    job.perform([document["_id"]], "govuk_test")

    expect(@processor).to have_received(:save).with(
      having_attributes(
        document: hash_including({ "supertype1" => "type1", "supertype2" => "type2", "title" => "test_doc" }),
      ),
    )
  end

  it "does not save if the supertype fields do not need to be updated" do
    document = {
      "_id" => "document_1",
      "_source" => {
        "title" => "test_doc",
        "content_store_document_type" => "testgroup",
        "supertype1" => "type1",
        "supertype2" => "type2",
      },
    }
    stub_document_lookups([document])
    job.perform([document["_id"]], "govuk_test")

    expect(@processor).not_to have_received(:save)
  end

  it "writes to the logger and continues to the next document if a document is not found" do
    document = { "_id" => "document_2", "_source" => { "content_store_document_type" => "testgroup" } }
    allow(index).to receive(:get_document_by_id).with("document_1").and_return(nil)
    allow(index).to receive(:get_document_by_id).with("document_2").and_return(document)
    logger = double(warn: true)
    allow(job).to receive(:logger).and_return(logger)

    document_ids = %w[document_1 document_2]
    job.perform(document_ids, "govuk_test")

    expect(@processor).to have_received(:save).once
    expect(logger).to have_received(:warn).with("Skipping document_1 as it is not in the index")
  end

  def stub_document_lookups(documents)
    allow(index).to receive(:get_document_by_id) do |document_id|
      documents.select { |document| document["_id"] == document_id }.first
    end
  end
end
