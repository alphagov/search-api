require "test_helper"
require "set"
require "unified_search_builder"

class UnifiedSearcherBuilderTest < ShouldaUnitTestCase

  context "unfiltered search" do
    setup do
      @builder = UnifiedSearchBuilder.new(0, 20, "cheese ", nil, {}, nil)
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

  end

  context "search with one filter" do
    setup do
      @builder = UnifiedSearchBuilder.new(0, 10, "cheese ", nil,
        {"organisations" => ["hm-magic"]}, nil)
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
  end

  context "search with a filter with multiple options" do
    setup do
      @builder = UnifiedSearchBuilder.new(0, 10, "cheese ", nil,
        {"organisations" => ["hm-magic", "hmrc"]}, nil)
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
  end

  context "search with multiple filters" do
    setup do
      @builder = UnifiedSearchBuilder.new(0, 10, "cheese ", nil,
        {
          "organisations" => ["hm-magic", "hmrc"],
          "section" => ["levitation"],
        }, nil)
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
  end

  context "building search with unicode" do
    setup do
      @builder = UnifiedSearchBuilder.new(0, 20, "cafe\u0300 ", nil, {}, nil)
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
      @builder = UnifiedSearchBuilder.new(0, 10, "cheese ", "public_timestamp", {}, nil)
    end

    should "have sort in payload" do
      assert_contains(
        @builder.payload.keys, :sort
      )
    end

    should "have filter in payload" do
      assert_contains(
        @builder.payload.keys, :filter
      )
    end

    should "have correct sort list" do
      assert_equal(
        [{"public_timestamp" => {order: "asc"}}],
        @builder.sort_list
      )
    end

    should "have correct filter hash" do
      assert_equal(
        {"exists" => {"field" => "public_timestamp"}},
        @builder.filters_hash
      )
    end
  end


  context "search with descending sort" do
    setup do
      @builder = UnifiedSearchBuilder.new(0, 10, "cheese ", "-public_timestamp", {}, nil)
    end

    should "have sort in payload" do
      assert_contains(
        @builder.payload.keys, :sort
      )
    end

    should "have filter in payload" do
      assert_contains(
        @builder.payload.keys, :filter
      )
    end

    should "have correct sort list" do
      assert_equal(
        [{"public_timestamp" => {order: "desc"}}],
        @builder.sort_list
      )
    end

    should "have correct filter hash" do
      assert_equal(
        {"exists" => {"field" => "public_timestamp"}},
        @builder.filters_hash
      )
    end
  end

  context "search with invalid parameters" do
    should "complain about disallowed filters" do
      assert_raises ArgumentError do
        UnifiedSearchBuilder.new(0, 10, "cheese", nil,
          {"spells" => ["levitation"]}, nil).payload
      end
    end

    should "complain about disallowed sort fields" do
      assert_raises ArgumentError do
        UnifiedSearchBuilder.new(0, 10, "cheese", "spells",
          {}, nil).payload
      end
    end

    should "complain about disallowed return fields" do
      assert_raises ArgumentError do
        UnifiedSearchBuilder.new(0, 10, "cheese", nil,
          {}, ["invalid_field"]).payload
      end
    end
  end

  context "search with explicit return fields" do
    setup do
      @builder = UnifiedSearchBuilder.new(0, 20, "cheese ", nil, {}, ['title'])
    end

    should "have correct fields in payload" do
      assert_equal(
        ['title'],
        @builder.payload[:fields]
      )
    end
  end

end
