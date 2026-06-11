require "spec_helper"

RSpec.describe SchemaSynchroniser do
  let(:index_name) { SearchConfig.govuk_index_name }
  before do
    clean_index_content(index_name)
  end

  it "synchronises the current Elasticsearch index schema with the schema defined by the search API" do
    index_group = search_server.index_group(index_name)
    mappings = index_group.current.mappings
    synchroniser = described_class.new(index_group)
    synchroniser.call
    expect(synchroniser.synchronised_types).not_to be_empty
    expect(synchroniser.synchronised_types).to eq(mappings.keys)
  end

  it "returns an error if the mappings are invalid" do
    index_group = search_server.index_group(index_name)
    mappings = index_group.current.mappings
    mappings["generic-document"].merge!("properties" => {
      "title" => {
        "type" => "not_a_real_type",
      },
    })
    synchroniser = described_class.new(index_group)
    result = synchroniser.call
    expect(result).to match("generic-document" => instance_of(Elasticsearch::Transport::Transport::Errors::BadRequest))
  end
end
