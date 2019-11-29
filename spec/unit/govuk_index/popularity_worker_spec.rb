require "spec_helper"

RSpec.describe GovukIndex::PopularityWorker do
  subject(:worker) { described_class.new }

  before do
    allow(GovukDocumentTypes).to receive(:supertypes).
      with(document_type: "testgroup").
      and_return("supertype1" => "type1", "supertype2" => "type2")
    @processor = instance_double("processor", save: nil, commit: nil)
    allow(Index::ElasticsearchProcessor).to receive(:new).and_return(@processor)
  end

  it "saves all records" do
    stub_popularity_data
    records = [
      { "identifier" => { "_id" => "record_1" }, "document" => {} },
      { "identifier" => { "_id" => "record_2" }, "document" => {} },
    ]
    worker.perform(records, "govuk_test")

    expect(@processor).to have_received(:save).twice
    expect(@processor).to have_received(:commit)
  end

  it "updates popularity field" do
    stub_popularity_data("record_1" => { popularity_score: 0.7, popularity_rank: 0.5 })

    @record = { "identifier" => { "_id" => "record_1" },
                "document" => { "title" => "test_doc" } }

    worker.perform([@record], "govuk_test")

    expect(@processor).to have_received(:save).with(
      having_attributes(
        identifier: { "_id" => "record_1", "version_type" => "external_gte", "_type" => "generic-document" },
        document: hash_including({ "popularity" => 0.7, "popularity_b" => 0.5, "title" => "test_doc" }),
      ),
    )
  end

  def stub_popularity_data(data = Hash.new({ popularity_score: 0.5, popularity_rank: 0.5 }))
    popularity_lookup = instance_double("popularity_lookup", lookup_popularities: data)
    allow(Indexer::PopularityLookup).to receive(:new).and_return(popularity_lookup)
  end
end
