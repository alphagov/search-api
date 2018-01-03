require 'spec_helper'

RSpec.describe 'ElasticsearchClosingTest' do
  before do
    stub_tagging_lookup
  end

  it "should fail to insert or get when index closed" do
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
