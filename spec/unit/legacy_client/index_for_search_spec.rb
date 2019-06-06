require 'spec_helper'

RSpec.describe LegacyClient::IndexForSearch do
  it "makes a request to elasticsearch for the alias name" do
    base_uri = SearchConfig.instance.base_uri
    alias_name = "some-alias"
    real_name = "some-index"

    get_request = stub_request(:get, "#{base_uri}/#{alias_name}/_alias")
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: {
          real_name => { 'aliases' => {} }
        }.to_json
      )

    index_for_search = described_class.new(base_uri, [alias_name], nil, nil)
    real_names = index_for_search.real_index_names

    assert_requested(get_request)
    expect(real_names).to eq([real_name])
  end
end
