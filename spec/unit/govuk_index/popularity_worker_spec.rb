require 'spec_helper'

RSpec.describe GovukIndex::PopularityWorker do
  it "should_save_all_records" do
    stub_popularity_data
    processor = double(:processor)
    allow(Index::ElasticsearchProcessor).to receive(:new).and_return(processor)
    records = [
      { 'identifier' => { '_id' => 'record_1' }, 'document' => {} },
      { 'identifier' => { '_id' => 'record_2' }, 'document' => {} },
    ]

    expect(processor).to receive(:save).twice
    expect(processor).to receive(:commit)

    subject.perform(records, "govuk_test")
  end

  it "should_update_popularity_field" do
    stub_popularity_data('record_1' => 0.7)

    processor = double(:processor)
    allow(Index::ElasticsearchProcessor).to receive(:new).and_return(processor)
    record = { 'identifier' => { '_id' => 'record_1' }, 'document' => { 'title' => 'test_doc' } }

    expect(processor).to receive(:save).with(
      OpenStruct.new(
        identifier: { '_id' => 'record_1', '_version_type' => 'external_gte' },
        document: { 'popularity' => 0.7, 'title' => 'test_doc' }
      )
    )
    expect(processor).to receive(:commit)

    subject.perform([record], "govuk_test")
  end

  def stub_popularity_data(data = Hash.new(0.5))
    popularity_lookup = double(:popularity_lookup)
    allow(Indexer::PopularityLookup).to receive(:new).and_return(popularity_lookup)
    allow(popularity_lookup).to receive(:lookup_popularities).and_return(data)
  end
end
