require "spec_helper"

RSpec.describe SchemaSynchroniser do
  before do
    clean_index_content("govuk_test")
  end

  it "synchronises the current Elasticsearch index schema with the schema defined by the search API" do
    index_group = search_server.index_group("govuk_test")
    mappings = index_group.current.mappings
    synchroniser = described_class.new(index_group)
    synchroniser.call
    expect(synchroniser.synchronised_types).not_to be_empty
    expect(synchroniser.synchronised_types).to eq(mappings.keys)
  end
end
