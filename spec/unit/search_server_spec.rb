require 'spec_helper'

RSpec.describe SearchIndices::SearchServer do
  def schema_config
    schema = double("schema config")
    allow(schema).to receive(:elasticsearch_mappings).and_return({})
    allow(schema).to receive(:elasticsearch_settings).and_return({})
    schema
  end

  it "returns an index" do
    search_server = described_class.new("http://l", schema_config, %w[government_test page-traffic_test], 'govuk_test', %w[government_test], SearchConfig.default_instance)
    index = search_server.index("government_test")
    expect(index).to be_a(SearchIndices::Index)
    expect(index.index_name).to eq("government_test")
  end

  it "returns an index for govuk index" do
    search_server = described_class.new("http://l", schema_config, %w[government_test page-traffic_test], 'govuk_test', %w[government_test], SearchConfig.default_instance)
    index = search_server.index("govuk_test")
    expect(index).to be_a(SearchIndices::Index)
    expect(index.index_name).to eq("govuk_test")
  end

  it "raises an error for unknown index" do
    search_server = described_class.new("http://l", schema_config, %w[government_test page-traffic_test], 'govuk_test', %w[government_test], SearchConfig.default_instance)
    expect {
      search_server.index("z")
    }.to raise_error(SearchIndices::NoSuchIndex)
  end

  it "can get multi index" do
    search_server = described_class.new("http://l", schema_config, %w[government_test page-traffic_test], 'govuk_test', %w[government_test], SearchConfig.default_instance)
    index = search_server.index_for_search(%w{government_test page-traffic_test})
    expect(index).to be_a(LegacyClient::IndexForSearch)
    expect(index.index_names).to eq(["government_test", "page-traffic_test"])
  end

  it "raises an error for unknown index in multi index" do
    search_server = described_class.new("http://l", schema_config, %w[government_test page-traffic_test], 'govuk_test', %w[government_test], SearchConfig.default_instance)
    expect {
      search_server.index_for_search(%w{government_test unknown})
    }.to raise_error(SearchIndices::NoSuchIndex)
  end
end
