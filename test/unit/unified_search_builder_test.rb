require "test_helper"
require "json"
require "set"
require "unified_search_builder"

class UnifiedSearcherBuilderTest < ShouldaUnitTestCase
  
  def stub_zero_best_bets
    @metasearch_index = stub("metasearch index")
    @metasearch_index.stubs(:raw_search).returns({
      "hits" => {"hits" => [], "total" => 0}
    })
    @metasearch_index.stubs(:analyzed_best_bet_query).returns("cheese")
  end

  def bb_doc(query, type, best_bets, worst_bets)
    {
      "_index" => "metasearch-2014-05-14t17:27:17z-bc245536-f1c1-4f95-83e4-596199b81f0a",
      "_type" => "best_bet",
      "_id" => "#{query}-#{type}",
      "_score" => 1.0,
      "fields" => {
        "details" => JSON.generate({
          best_bets: best_bets.map do |link, position|
            {link: link, position: position}
          end,
          worst_bets: worst_bets.map do |link|
            {link: link}
          end,
        })
      }
    }
  end

  def setup_best_bets(best_bets, worst_bets)
    @metasearch_index = stub("metasearch index")
    @metasearch_index.stubs(:raw_search).returns({
      "hits" => {"hits" => [
        bb_doc("cheese", "exact", best_bets, worst_bets)
      ], "total" => 1}
    })
    @metasearch_index.expects(:analyzed_best_bet_query).returns("cheese")
  end

  def setup_best_bets_query(best_bets, worst_bets)
    params = {
      start: 0,
      count: 10,
      query: "cheese ",
      order: nil,
      filters: {},
      fields: nil,
      facets: nil,
      debug: {},
    }
    setup_best_bets([], [])
    @builder_without_best_bets = UnifiedSearchBuilder.new(params, @metasearch_index)
    @query_without_best_bets = @builder_without_best_bets.payload[:query]
    setup_best_bets(best_bets, worst_bets)
    @builder = UnifiedSearchBuilder.new(params, @metasearch_index)
  end

  context "unfiltered search" do
    setup do
      stub_zero_best_bets
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 20,
        query: "cheese",
        order: nil,
        filters: {},
        fields: nil,
        facets: nil,
        debug: {},
      }, @metasearch_index)
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
      stub_zero_best_bets
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {"organisations" => ["hm-magic"]},
        fields: nil,
        facets: nil,
        debug: {},
      }, @metasearch_index)
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
      stub_zero_best_bets
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {"organisations" => ["hm-magic", "hmrc"]},
        fields: nil,
        facets: nil,
        debug: {},
      }, @metasearch_index)
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
      stub_zero_best_bets
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
        debug: {},
      }, @metasearch_index)
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
      stub_zero_best_bets
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cafe\u0300 ",
        order: nil,
        filters: {},
        fields: nil,
        facets: nil,
        debug: {},
      }, @metasearch_index)

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
      stub_zero_best_bets
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: ["public_timestamp", "asc"],
        filters: {},
        fields: nil,
        facets: nil,
        debug: {},
      }, @metasearch_index)
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
      stub_zero_best_bets
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: ["public_timestamp", "desc"],
        filters: {},
        fields: nil,
        facets: nil,
        debug: {},
      }, @metasearch_index)
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
      stub_zero_best_bets
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {},
        return_fields: ['title'],
        facets: nil,
        debug: {},
      }, @metasearch_index)
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
      stub_zero_best_bets
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {},
        fields: nil,
        facets: {"organisations" => 10},
        debug: {},
      }, @metasearch_index)
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
      stub_zero_best_bets
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {"organisations" => ["hm-magic"]},
        fields: nil,
        facets: {"organisations" => 10},
        debug: {},
      }, @metasearch_index)
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
      stub_zero_best_bets
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 10,
        query: "cheese ",
        order: nil,
        filters: {"section" => ["levitation"]},
        fields: nil,
        facets: {"organisations" => 10},
        debug: {},
      }, @metasearch_index)
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

  context "search with a single best bet url" do
    setup do
      setup_best_bets_query([["/foo", 1]], [])
    end

    should "have correct query in payload" do
      assert_equal(
        {
          bool: {
            should: [
              @query_without_best_bets,
              {
                custom_boost_factor: {
                  query: {
                    ids: { values: ["/foo"] },
                  },
                  boost_factor: 1000000,
                }
              }
            ]
          }
        },
        @builder.payload[:query])
    end
  end

  context "search with two best bet urls" do
    setup do
      setup_best_bets_query([["/foo", 1], ["/bar", 2]], [])
    end

    should "have correct query in payload" do
      assert_equal(
        {
          bool: {
            should: [
              @query_without_best_bets,
              {
                custom_boost_factor: {
                  query: { ids: { values: ["/foo"] }, },
                  boost_factor: 2000000,
                }
              },
              {
                custom_boost_factor: {
                  query: { ids: { values: ["/bar"] }, },
                  boost_factor: 1000000,
                }
              }
            ]
          }
        },
        @builder.payload[:query])
    end
  end

  context "search with a worst bet" do
    setup do
      setup_best_bets_query([], ["/foo"])
    end

    should "have correct query in payload" do
      assert_equal(
        {
          bool: {
            should: [
              @query_without_best_bets,
            ],
            must_not: [
              { ids: { values: ["/foo"] } }
            ],
          }
        },
        @builder.payload[:query])
    end
  end

  context "search with debug disabling use of best bets" do
    setup do
      # No need to set up best bets query.
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 20,
        query: "cheese",
        order: nil,
        filters: {},
        fields: nil,
        facets: nil,
        debug: {disable_best_bets: true},
      }, @metasearch_index)
    end

    should "have not have a bool query in payload" do
      assert @builder.payload[:query].keys != [:bool]
    end
  end

  context "search with debug disabling use of popularity" do
    setup do
      stub_zero_best_bets
      @builder = UnifiedSearchBuilder.new({
        start: 0,
        count: 20,
        query: "cheese",
        order: nil,
        filters: {},
        fields: nil,
        facets: nil,
        debug: {disable_popularity: true},
      }, @metasearch_index)
    end

    should "have not have a custom_score clause to add popularity in payload" do
      query = @builder.payload[:query]
      refute_match(/popularity/, query.to_s)
      assert query[:indices][:query][:custom_boost_factor][:query].keys == [:custom_filters_score]
    end
  end
end
