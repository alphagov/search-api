require "spec_helper"

RSpec.describe CombinedIndexSchema do
  before do
    search_config = SearchConfig.default_instance
    @index_names = SearchConfig.content_index_names + [SearchConfig.govuk_index_name]
    @combined_schema = described_class.new(@index_names, search_config.schema_config)
  end

  it "basic field definitions" do
    # The title and public_timestamp fields are defined in the
    # base_elasticsearch_type, so are available in all documents holding content.
    expect(@combined_schema.field_definitions["title"].type.name).to eq("searchable_sortable_text")
    expect(@combined_schema.field_definitions["description"].type.name).to eq("searchable_text")
    expect(@combined_schema.field_definitions["public_timestamp"].type.name).to eq("date")
  end

  it "allowed filter fields" do
    expect(@combined_schema.allowed_filter_fields).not_to include "title"
    expect(@combined_schema.allowed_filter_fields).to include "organisations"
  end
end
