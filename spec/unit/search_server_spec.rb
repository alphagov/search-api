require "spec_helper"

RSpec.describe SearchIndices::SearchServer do
  let(:govuk_index_name) { SearchConfig.govuk_index_name }
  def schema_config
    schema = double("schema config")
    allow(schema).to receive(:elasticsearch_mappings).and_return({})
    allow(schema).to receive(:elasticsearch_settings).and_return({})
    schema
  end

  it "returns an index" do
    search_server = described_class.new("http://l", schema_config, SearchConfig.default_instance)
    index = search_server.index(SearchConfig.page_traffic_index_name)
    expect(index).to be_a(SearchIndices::Index)
    expect(index.index_name).to eq(SearchConfig.page_traffic_index_name)
  end

  it "returns an index for govuk index" do
    search_server = described_class.new("http://l", schema_config, SearchConfig.default_instance)
    index = search_server.index(govuk_index_name)
    expect(index).to be_a(SearchIndices::Index)
    expect(index.index_name).to eq(govuk_index_name)
  end

  it "raises an error for unknown index" do
    search_server = described_class.new("http://l", schema_config, SearchConfig.default_instance)
    expect {
      search_server.index("unknown")
    }.to raise_error(SearchIndices::NoSuchIndex)
  end
end
