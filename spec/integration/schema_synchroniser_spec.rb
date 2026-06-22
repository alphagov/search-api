require "spec_helper"

RSpec.describe SchemaSynchroniser do
  let(:index_name) { SearchConfig.govuk_index_name }
  let(:logger) { Logger.new(output) }
  let(:output) { StringIO.new }
  let(:synchroniser) { SchemaSynchroniser.new(index_name) }

  before do
    clean_index_content(index_name)
  end

  it "synchronises successfully and logs the result" do
    mapping = { "properties" => { "test" => { "type" => "keyword" } } }

    expect {
      synchroniser.sync_mappings(mapping, logger)
    }.to_not raise_error

    expect(output.string).to include("Updated mappings for index: #{index_name}")
  end

  it "raises an error if the mappings are invalid" do
    mapping = { "properties" => { "test" => { "type" => "not-a-type" } } }

    expect {
      synchroniser.sync_mappings(mapping, logger)
    }.to raise_error(Elasticsearch::Transport::Transport::Errors::BadRequest)

    expect(output.string).to include("Unable to update mappings for index: #{index_name};")
  end

  it "adds the 'test' property to the existing schema" do
    mapping = { "properties" => { "test" => { "type" => "keyword" } } }

    synchroniser.sync_mappings(mapping, logger)

    response = Services.elasticsearch.indices.get_mapping(index: SearchConfig.govuk_index_name)
    expect(response.values.dig(0, "mappings", "generic-document", "properties", "test")).to eq({ "type" => "keyword" })
  end
end
