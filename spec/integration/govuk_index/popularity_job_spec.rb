require "spec_helper"

RSpec.describe GovukIndex::PopularityJob do
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

  it "saves the documents with the popularity fields values" do
    stub_popularity_data(
      {
        "document_1" => { popularity_score: 0.7, popularity_rank: 0.5 },
        "document_2" => { popularity_score: 0.6, popularity_rank: 0.5 },
      },
    )
    documents = [
      { "_id" => "document_1", "_version" => 1, "_source" => { "title" => "test_doc1" } },
      { "_id" => "document_2", "_version" => 1, "_source" => { "title" => "test_doc2" } },
    ]
    stub_document_lookups(documents)

    document_ids = documents.map { |document| document["_id"] }
    job.perform(document_ids, "govuk_test")

    expect(@processor).to have_received(:save).with(
      having_attributes(
        identifier: { "_id" => "document_1", "_version" => 1, "version_type" => "external_gte", "_type" => "generic-document" },
        document: hash_including({ "popularity" => 0.7, "popularity_b" => 0.5, "title" => "test_doc1" }),
      ),
    ).once
    expect(@processor).to have_received(:save).with(
      having_attributes(
        identifier: { "_id" => "document_2", "_version" => 1, "version_type" => "external_gte", "_type" => "generic-document" },
        document: hash_including({ "popularity" => 0.6, "popularity_b" => 0.5, "title" => "test_doc2" }),
      ),
    ).once
    expect(@processor).to have_received(:commit)
  end

  it "writes to the logger and continues to the next document if a document is not found" do
    stub_popularity_data({ "document_2" => { popularity_score: 0.6, popularity_rank: 0.5 } })
    document = { "_id" => "document_2", "_source" => { "title" => "test_doc2" } }
    allow(index).to receive(:get_document_by_id).with("document_1").and_return(nil)
    allow(index).to receive(:get_document_by_id).with("document_2").and_return(document)
    logger = double(warn: true)
    allow(job).to receive(:logger).and_return(logger)

    document_ids = %w[document_1 document_2]
    job.perform(document_ids, "govuk_test")

    expect(@processor).to have_received(:save).with(
      having_attributes(
        identifier: { "_id" => "document_2", "version_type" => "external_gte", "_type" => "generic-document" },
        document: hash_including({ "popularity" => 0.6, "popularity_b" => 0.5, "title" => "test_doc2" }),
      ),
    ).once
    expect(logger).to have_received(:warn).with("Skipping document_1 as it is not in the index")
  end

  def stub_popularity_data(data = Hash.new({ popularity_score: 0.5, popularity_rank: 0.5 }))
    popularity_lookup = instance_double("popularity_lookup", lookup_popularities: data)
    allow(Indexer::PopularityLookup).to receive(:new).and_return(popularity_lookup)
  end

  def stub_document_lookups(documents)
    allow(index).to receive(:get_document_by_id) do |document_id|
      documents.select { |document| document["_id"] == document_id }.first
    end
  end
end
