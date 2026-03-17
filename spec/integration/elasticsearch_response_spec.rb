require "spec_helper"

RSpec.describe ElasticsearchResponse do
  let(:index) { "govuk_test" }
  let(:response) { Services.elasticsearch.search(index:, body: { size: 0 }) }

  it "returns 0 hits" do
    expect(ElasticsearchResponse.new(response).total_hits).to eq 0
  end

  it "returns 1 hit" do
    commit_document(index, { some: "data" }, id: "ABC")
    results = ElasticsearchResponse.new(response).total_hits
    expect(results).to eq 1
  end

end
