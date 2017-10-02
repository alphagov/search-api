require 'spec_helper'

RSpec.describe 'ElasticsearchClosingTest', tags: ['integration'] do
  allow_elasticsearch_connection

  before do
    stub_tagging_lookup
  end

  it "should_fail_to_insert_or_get_when_index_closed" do
    index = search_server.index_group(SearchConfig.instance.default_index_name).current
    index.close

    expect {
      index.add([sample_document])
    }.to raise_error(Indexer::BulkIndexFailure)

    # Re-opening the index again, as they are not recreated on each test run
    # anymore.
    client.indices.open(index: SearchConfig.instance.default_index_name)
  end
end
