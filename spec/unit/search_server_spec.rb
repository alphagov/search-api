require 'spec_helper'

RSpec.describe SearchIndices::SearchServer do
  def schema_config
    schema = double("schema config")
    allow(schema).to receive(:elasticsearch_mappings).and_return({})
    allow(schema).to receive(:elasticsearch_settings).and_return({})
    schema
  end

  it "returns_an_index" do
    search_server = described_class.new("http://l", schema_config, ["mainstream_test", "page-traffic_test"], 'govuk_test', ["mainstream_test"], SearchConfig.new)
    index = search_server.index("mainstream_test")
    expect(index).to be_a(SearchIndices::Index)
    expect("mainstream_test").to eq(index.index_name)
  end

  it "returns_an_index_for_govuk_index" do
    search_server = described_class.new("http://l", schema_config, ["mainstream_test", "page-traffic_test"], 'govuk_test', ["mainstream_test"], SearchConfig.new)
    index = search_server.index("govuk_test")
    expect(index).to be_a(SearchIndices::Index)
    expect("govuk_test").to eq(index.index_name)
  end

  it "raises_an_error_for_unknown_index" do
    search_server = described_class.new("http://l", schema_config, ["mainstream_test", "page-traffic_test"], 'govuk_test', ["mainstream_test"], SearchConfig.new)
    expect {
      search_server.index("z")
    }.to raise_error(SearchIndices::NoSuchIndex)
  end

  it "can_get_multi_index" do
    search_server = described_class.new("http://l", schema_config, ["mainstream_test", "page-traffic_test"], 'govuk_test', ["mainstream_test"], SearchConfig.new)
    index = search_server.index_for_search(%w{mainstream_test page-traffic_test})
    expect(index).to be_a(LegacyClient::IndexForSearch)
    expect(["mainstream_test", "page-traffic_test"]).to eq(index.index_names)
  end

  it "raises_an_error_for_unknown_index_in_multi_index" do
    search_server = described_class.new("http://l", schema_config, ["mainstream_test", "page-traffic_test"], 'govuk_test', ["mainstream_test"], SearchConfig.new)
    expect {
      search_server.index_for_search(%w{mainstream_test unknown})
    }.to raise_error(SearchIndices::NoSuchIndex)
  end
end
