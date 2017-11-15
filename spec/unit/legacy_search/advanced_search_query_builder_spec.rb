require 'spec_helper'

RSpec.describe LegacySearch::AdvancedSearchQueryBuilder do
  include Fixtures::DefaultMappings

  def build_builder(keywords = "", filter_params = {}, sort_order = {}, mappings = default_mappings)
    described_class.new(keywords, filter_params, sort_order, mappings)
  end

  it "builder_excludes_withdrawn" do
    builder = build_builder
    query_hash = builder.filter_query_hash

    expect(query_hash).to eq(
      "filter" => {
        "not" => { "term" => { "is_withdrawn" => true } }
      }
    )
  end


  it "builder_single_filters" do
    builder = build_builder("how to drive", { "format" => "organisation" })
    query_hash = builder.filter_query_hash

    expect(query_hash).to eq(
      "filter" => {
        "and" => [
          { "term" => { "format" => "organisation" } },
          { "not" => { "term" => { "is_withdrawn" => true } } }
        ]
      }
    )
  end

  it "builder_multiple_filters" do
    builder = build_builder("how to drive", { "format" => "organisation", "specialist_sectors" => "driving" })
    query_hash = builder.filter_query_hash

    expect(query_hash).to eq(
      "filter" => {
        "and" => [
          { "term" => { "format" => "organisation" } },
          { "term" => { "specialist_sectors" => "driving" } },
          { "not" => { "term" => { "is_withdrawn" => true } } }
        ]
      }
    )
  end

  it "ignores empty filters" do
    builder = build_builder("how to drive", { "format" => "organisation", "specialist_sectors" => "driving", "people" => nil })
    query_hash = builder.filter_query_hash

    expect(query_hash).to eq(
      "filter" => {
        "and" => [
          { "term" => { "format" => "organisation" } },
          { "term" => { "specialist_sectors" => "driving" } },
          { "not" => { "term" => { "is_withdrawn" => true } } }
        ]
      }
    )
  end
end
