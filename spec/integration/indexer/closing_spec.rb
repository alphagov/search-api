require "spec_helper"

RSpec.describe "ElasticsearchClosingTest" do
  before do
    stub_tagging_lookup
  end

  it "will not allow insertion into closed index" do
    index = search_server.index_group("govuk_test").current
    index.close

    expect {
      index.add([sample_document])
    }.to raise_error(Indexer::BulkIndexFailure)

    # Re-opening the index again, as they are not recreated on each test run
    # anymore.
    client.indices.open(index: "govuk_test")
  end
end
