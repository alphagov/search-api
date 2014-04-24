require "test_helper"
require "set"
require "unified_search_builder"

class UnifiedSearcherBuilderTest < ShouldaUnitTestCase

  context "unfiltered search" do
    setup do
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 20,
        query: "cheese",
        order: nil,
        filters: {},
        fields: nil,
        facets: nil,
      })
    end

    should "strip whitespace from the query" do
      assert_equal(
        "cheese",
        @builder.query_normalized
      )
    end

    should "have correct 'from' parameter in payload" do
      assert_equal(
        0,
        @builder.payload[:from]
      )
    end

    should "have correct 'size' parameter in payload" do
      assert_equal(
        20,
        @builder.payload[:size]
      )
    end

    should "not have filter in payload" do
      assert_does_not_contain(
        @builder.payload.keys, :filter
      )
    end

    should "not have facets in payload" do
      assert_does_not_contain(
        @builder.payload.keys, :facets
      )
    end

  end

  context "search with one filter" do
    setup do
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {"organisations" => ["hm-magic"]},
        fields: nil,
        facets: nil,
      })
    end

    should "have filter in payload" do
      assert_contains(
        @builder.payload.keys, :filter
      )
    end

    should "have correct filter" do
      assert_equal(
        @builder.filters_hash, {"terms" => {"organisations" => ["hm-magic"]}}
      )
    end

    should "not have facets in payload" do
      assert_does_not_contain(
        @builder.payload.keys, :facets
      )
    end
  end

  context "search with a filter with multiple options" do
    setup do
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {"organisations" => ["hm-magic", "hmrc"]},
        fields: nil,
        facets: nil,
      })
    end

    should "have filter in payload" do
      assert_contains(
        @builder.payload.keys, :filter
      )
    end

    should "have correct filter" do
      assert_equal(
        @builder.filters_hash,
        {"terms" => {"organisations" => ["hm-magic", "hmrc"]}}
      )
    end

    should "not have facets in payload" do
      assert_does_not_contain(
        @builder.payload.keys, :facets
      )
    end
  end

  context "search with multiple filters" do
    setup do
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {
          "organisations" => ["hm-magic", "hmrc"],
          "section" => ["levitation"],
        },
        fields: nil,
        facets: nil,
      })
    end

    should "have filter in payload" do
      assert_contains(
        @builder.payload.keys, :filter
      )
    end

    should "have correct filter" do
      assert_equal(
        @builder.filters_hash,
        {"and" => [
          {"terms" => {"organisations" => ["hm-magic", "hmrc"]}},
          {"terms" => {"section" => ["levitation"]}},
        ]}
      )
    end

    should "not have facets in payload" do
      assert_does_not_contain(
        @builder.payload.keys, :facets
      )
    end
  end

  context "building search with unicode" do
    setup do
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cafe\u0300 ",
        order: nil,
        filters: {},
        fields: nil,
        facets: nil,
      })

    end

    should "put the query in normalized form" do
      assert_equal(
        "caf\u00e8",
        @builder.query_normalized
      )
    end
  end

  context "search with ascending sort" do
    setup do
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: ["public_timestamp", "asc"],
        filters: {},
        fields: nil,
        facets: nil,
      })
    end

    should "have sort in payload" do
      assert_contains(
        @builder.payload.keys, :sort
      )
    end

    should "not have filter in payload" do
      assert_does_not_contain(
        @builder.payload.keys, :filter
      )
    end

    should "not have facets in payload" do
      assert_does_not_contain(
        @builder.payload.keys, :facets
      )
    end

    should "have correct sort list" do
      assert_equal(
        [{"public_timestamp" => {order: "asc"}}],
        @builder.sort_list
      )
    end

    should "have filter in query hash" do
      assert_equal(
        {"exists" => {"field" => "public_timestamp"}},
        @builder.query_hash[:indices][:query][:custom_boost_factor][:query][:filtered][:filter]
      )
      assert_equal(
        {"exists" => {"field" => "public_timestamp"}},
        @builder.query_hash[:indices][:no_match_query][:filtered][:filter]
      )
    end
  end


  context "search with descending sort" do
    setup do
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: ["public_timestamp", "desc"],
        filters: {},
        fields: nil,
        facets: nil,
      })
    end

    should "have sort in payload" do
      assert_contains(
        @builder.payload.keys, :sort
      )
    end

    should "not have filter in payload" do
      assert_does_not_contain(
        @builder.payload.keys, :filter
      )
    end

    should "not have facets in payload" do
      assert_does_not_contain(
        @builder.payload.keys, :facets
      )
    end

    should "have correct sort list" do
      assert_equal(
        [{"public_timestamp" => {order: "desc"}}],
        @builder.sort_list
      )
    end

    should "have filter in query hash" do
      assert_equal(
        {"exists" => {"field" => "public_timestamp"}},
        @builder.query_hash[:indices][:query][:custom_boost_factor][:query][:filtered][:filter]
      )
      assert_equal(
        {"exists" => {"field" => "public_timestamp"}},
        @builder.query_hash[:indices][:no_match_query][:filtered][:filter]
      )
    end
  end

  context "search with explicit return fields" do
    setup do
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {},
        return_fields: ['title'],
        facets: nil,
      })
    end

    should "have correct fields in payload" do
      assert_equal(
        ['title'],
        @builder.payload[:fields]
      )
    end
  end

  context "search with facet" do
    setup do
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {},
        fields: nil,
        facets: {"organisations" => 10},
      })
    end

    should "not have filter in payload" do
      assert_does_not_contain(
        @builder.payload.keys, :filter
      )
    end

    should "have correct facet in payload" do
      assert_equal(
        {
          "organisations" => {
            terms: {
              field: "organisations",
              order: "count",
              size: 100000,
            }
          },
        },
        @builder.payload[:facets])
    end
  end

  context "search with facet and filter on same field" do
    setup do
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {"organisations" => ["hm-magic"]},
        fields: nil,
        facets: {"organisations" => 10},
      })
    end

    should "have correct filter" do
      assert_equal(
        @builder.filters_hash, {"terms" => {"organisations" => ["hm-magic"]}}
      )
    end

    should "have correct facet in payload" do
      assert_equal(
        {
          "organisations" => {
            terms: {
              field: "organisations",
              order: "count",
              size: 100000,
            }
          },
        },
        @builder.payload[:facets])
    end
  end

  context "search with facet and filter on different field" do
    setup do
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {"section" => ["levitation"]},
        fields: nil,
        facets: {"organisations" => 10},
      })
    end

    should "have correct filter" do
      assert_equal(
        @builder.filters_hash, {"terms" => {"section" => ["levitation"]}}
      )
    end

    should "have facet with facet_filter in payload" do
      assert_equal(
        {
          "organisations" => {
            terms: {
              field: "organisations",
              order: "count",
              size: 100000,
            },
            facet_filter: {
              "terms" => {"section" => ["levitation"]}
            },
          },
        },
        @builder.payload[:facets])
    end
  end

end
