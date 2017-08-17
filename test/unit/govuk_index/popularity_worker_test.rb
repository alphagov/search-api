require 'test_helper'

class PopularityWorkerTest < Minitest::Test
  def test_should_save_all_records
    stub_popularity_data
    processor = stub(:processor)
    GovukIndex::ElasticsearchProcessor.stubs(:new).returns(processor)
    records = [
      { 'identifier' => { '_id' => 'record_1' }, 'document' => {} },
      { 'identifier' => { '_id' => 'record_2' }, 'document' => {} },
    ]

    processor.expects(:save).times(2)
    processor.expects(:commit)

    GovukIndex::PopularityWorker.new.perform(records, "govuk_test")
  end

  def test_should_update_popularity_field
    stub_popularity_data('record_1' => 0.7)

    processor = stub(:processor)
    GovukIndex::ElasticsearchProcessor.stubs(:new).returns(processor)
    record = { 'identifier' => { '_id' => 'record_1' }, 'document' => { 'title' => 'test_doc' } }

    processor.expects(:save).with(
      OpenStruct.new(
        identifier: { '_id' => 'record_1', '_version_type' => 'external_gte' },
        document: { 'popularity' => 0.7, 'title' => 'test_doc' }
      )
    )
    processor.expects(:commit)

    GovukIndex::PopularityWorker.new.perform([record], "govuk_test")
  end

  def stub_popularity_data(data = Hash.new(0.5))
    popularity_lookup = stub(:popularity_lookup)
    Indexer::PopularityLookup.stubs(:new).returns(popularity_lookup)
    popularity_lookup.stubs(:lookup_popularities).returns(data)
  end
end
