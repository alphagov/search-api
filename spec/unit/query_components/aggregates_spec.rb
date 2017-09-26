require 'spec_helper'

RSpec.describe QueryComponents::Aggregates, tags: ['shoulda'] do
  def make_search_params(aggregates:, filters: [])
    Search::QueryParameters.new(
      filters: filters, aggregates: aggregates, debug: { include_withdrawn: true }
    )
  end

  context "search with aggregate" do
    it "have correct aggregate in payload" do
      builder = described_class.new(
        make_search_params(
          aggregates: { "organisations" => { requested: 10, scope: :exclude_field_filter } },
        )
      )

      result = builder.payload

      assert_equal(
        {
          "organisations" => {
            filter: { match_all: {} },
            aggs: {
              "filtered_aggregations" => {
                terms: {
                  field: "organisations",
                  order: { _count: "desc" },
                  size: 100000,
                }
              }
            }
          },
          "organisations_with_missing_value" => {
            filter: { match_all: {} },
            aggs: {
              "filtered_aggregations" => {
                missing: { field: "organisations" }
              }
            }
          },
        },
        result
      )
    end
  end

  context "search with aggregate and filter on same field" do
    before do
      @builder = described_class.new(
        make_search_params(
          filters: [text_filter("organisations", ["hm-magic"])],
          aggregates: { "organisations" => { requested: 10, scope: :exclude_field_filter } },
        )
      )
    end

    it "have correct aggregate in payload" do
      assert_equal(
        {
          "organisations" => {
            filter: { match_all: {} },
            aggs: {
              "filtered_aggregations" => {
                terms: {
                  field: "organisations",
                  order: { _count: "desc" },
                  size: 100000,
                }
              }
            }
          },
          "organisations_with_missing_value" => {
            filter: { match_all: {} },
            aggs: {
              "filtered_aggregations" => {
                missing: { field: "organisations" }
              }
            }
          },
        },
        @builder.payload)
    end
  end

  context "search with aggregate and filter on same field, and scope set to all_filters" do
    before do
      @builder = described_class.new(
        make_search_params(
          filters: [text_filter("organisations", ["hm-magic"])],
          aggregates: { "organisations" => { requested: 10, scope: :all_filters } },
        )
      )
    end

    it "have correct aggregate in payload" do
      assert_equal(
        {
          "organisations" => {
            filter: {
              "terms" => { "organisations" => ["hm-magic"] },
            },
            aggs: {
              'filtered_aggregations' => {
                terms: {
                  field: "organisations",
                  order: { _count: "desc" },
                  size: 100000,
                }
              }
            },
          },
          "organisations_with_missing_value" => {
            filter: {
              "terms" => { "organisations" => ["hm-magic"] }
            },
            aggs: {
              'filtered_aggregations' => {
                missing: { field: "organisations" }
              }
            }
          }
        },
        @builder.payload)
    end
  end

  context "search with aggregate and filter on different field" do
    before do
      @builder = described_class.new(
        make_search_params(
          filters: [text_filter("mainstream_browse_pages", "levitation")],
          aggregates: { "organisations" => { requested: 10, scope: :exclude_field_filter } },
        )
      )
    end

    it "have aggregate with aggregate_filter in payload" do
      assert_equal(
        {
          "organisations" => {
            filter: {
              "terms" => { "mainstream_browse_pages" => ["levitation"] },
            },
            aggs: {
              'filtered_aggregations' => {
                terms: {
                  field: "organisations",
                  order: { _count: "desc" },
                  size: 100000,
                }
              },
            },
          },
          "organisations_with_missing_value" => {
            filter: {
              "terms" => {
                "mainstream_browse_pages" => ["levitation"]
              }
            },
            aggs: {
              'filtered_aggregations' => {
                missing: { field: "organisations" }
              }
            }
          },
        },
        @builder.payload)
    end
  end

  def text_filter(field_name, values, reject = false)
    SearchParameterParser::TextFieldFilter.new(field_name, values, reject)
  end
end
