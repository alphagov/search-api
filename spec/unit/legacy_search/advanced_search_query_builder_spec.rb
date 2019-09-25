require "spec_helper"

RSpec.describe LegacySearch::AdvancedSearchQueryBuilder do
  include Fixtures::DefaultMappings

  def build_builder(keywords = "", filter_params = {}, sort_order = {}, mappings = default_mappings)
    described_class.new(keywords, filter_params, sort_order, mappings)
  end

  it "builder excludes withdrawn" do
    builder = build_builder
    query_hash = builder.filter_array

    expect(query_hash).to eq(
      [{ bool: { must_not: { term: { is_withdrawn: true } } } }]
    )
  end


  it "builder single filters" do
    builder = build_builder("how to drive", { "format" => "organisation" })
    query_hash = builder.filter_array

    expect(query_hash).to eq(
      [
        { "term" => { "format" => "organisation" } },
        { bool: { must_not: { term: { is_withdrawn: true } } } }
      ]
    )
  end

  it "builder multiple filters" do
    builder = build_builder("how to drive", { "format" => "organisation", "specialist_sectors" => "driving" })
    query_hash = builder.filter_array

    expect(query_hash).to eq(
      [
        { "term" => { "format" => "organisation" } },
        { "term" => { "specialist_sectors" => "driving" } },
        { bool: { must_not: { term: { is_withdrawn: true } } } }
      ]
    )
  end

  it "ignores empty filters" do
    builder = build_builder("how to drive", { "format" => "organisation", "specialist_sectors" => "driving", "people" => nil })
    query_hash = builder.filter_array

    expect(query_hash).to eq(
      [
        { "term" => { "format" => "organisation" } },
        { "term" => { "specialist_sectors" => "driving" } },
        { bool: { must_not: { term: { is_withdrawn: true } } } }
      ]
    )
  end
end
