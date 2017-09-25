require 'spec_helper'

RSpec.describe 'ElasticsearchClosingTest', tags: ['integration'] do
  before do
    stub_tagging_lookup
  end

  it "should_fail_to_insert_or_get_when_index_closed" do
    index = search_server.index_group(IndexHelpers::DEFAULT_INDEX_NAME).current
    index.close

    assert_raises Indexer::BulkIndexFailure do
      index.add([sample_document])
    end

    # Re-opening the index again, as they are not recreated on each test run
    # anymore.
    client.indices.open(index: IndexHelpers::DEFAULT_INDEX_NAME)
  end
end
