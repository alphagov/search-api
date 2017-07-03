require "test_helper"
require "search/query_builder"

class AggregatesTest < ShouldaUnitTestCase
  def make_search_params(aggregates:, filters: [])
    Search::QueryParameters.new(
      filters: filters, aggregates: aggregates, debug: { include_withdrawn: true }
    )
  end

  context "search with aggregate" do
    should "have correct aggregate in payload" do
      builder = QueryComponents::Aggregates.new(
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
    setup do
      @builder = QueryComponents::Aggregates.new(
        make_search_params(
          filters: [text_filter("organisations", ["hm-magic"])],
          aggregates: { "organisations" => { requested: 10, scope: :exclude_field_filter } },
        )
      )
    end

    should "have correct aggregate in payload" do
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
    setup do
      @builder = QueryComponents::Aggregates.new(
        make_search_params(
          filters: [text_filter("organisations", ["hm-magic"])],
          aggregates: { "organisations" => { requested: 10, scope: :all_filters } },
        )
      )
    end

    should "have correct aggregate in payload" do
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
    setup do
      @builder = QueryComponents::Aggregates.new(
        make_search_params(
          filters: [text_filter("mainstream_browse_pages", "levitation")],
          aggregates: { "organisations" => { requested: 10, scope: :exclude_field_filter } },
        )
      )
    end

    should "have aggregate with aggregate_filter in payload" do
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
