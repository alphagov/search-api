require "test_helper"
require "set"
require "unified_searcher"

class UnifiedSearcherTest < ShouldaUnitTestCase

  def sample_docs
    [{
      "_index" => "government-2014-03-19t14:35:28z-a05cfc73-933a-41c7-adc0-309a715baf09",
      _type: "edition",
      _id: "/government/publications/staffordshire-cheese",
      _score: 3.0514863,
      "fields" => {
        "description" => "Staffordshire Cheese Product of Designated Origin (PDO) and Staffordshire Organic Cheese.",
        "title" => "Staffordshire Cheese",
        "link" => "/government/publications/staffordshire-cheese",
      },
    }, {
      "_index" => "mainstream-2014-03-19t14:35:28z-6472f975-dc38-49a5-98eb-c498e619650c",
      _type: "edition",
      _id: "/duty-relief-for-imports-and-exports",
      _score: 0.49672604,
      "fields" => {
        "description" => "Schemes that offer reduced or zero rate duty and VAT for imports and exports",
        "title" => "Duty relief for imports and exports",
        "link" => "/duty-relief-for-imports-and-exports",
      },
    }, {
      "_index" => "detailed-2014-03-19t14:35:27z-27e2831f-bd14-47d8-9c7a-3017e213efe3",
      _type: "edition",
      _id: "/dairy-farming-and-schemes",
      _score: 0.34655035,
      "fields" => {
        "description" => "Information on hygiene standards and milking practices for UK dairy farmers, with a guide to EU schemes for dairy farmers and producers",
        "title" => "Dairy farming and schemes",
        "link" => "/dairy-farming-and-schemes",
      },
    }]
  end

  CHEESE_QUERY = {
    match: {
      _all: {
        query: "cheese"
      }
    }
  }

  TIMESTAMP_EXISTS_WITH_CHEESE_QUERY = {
    filtered: {
      filter: {"exists" => {"field" => "public_timestamp"}},
      query: CHEESE_QUERY,
    }
  }

  context "unfiltered, unsorted search" do

    setup do
      @combined_index = stub("unified index")
      @searcher = UnifiedSearcher.new(@combined_index, {}, {})
      @combined_index.expects(:raw_search).with({
        from: 0,
        size: 20,
        query: CHEESE_QUERY,
        fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
      }).returns({
        "hits" => {"hits" => sample_docs, "total" => 3}
      })
      @combined_index.expects(:index_name).returns(
        "mainstream,detailed,government"
      )

      @results = @searcher.search({
        start: 0,
        count: 20,
        query: "cheese",
        order: nil,
        filters: {},
        return_fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
      })
    end

    should "include results from all indexes" do
      assert_equal(
        ["government", "mainstream", "detailed"].to_set,
        @results[:results].map { |result|
          result[:index]
        }.to_set
      )
    end

    should "include total result count" do
      assert_equal(3, @results[:total])
    end
  end

  context "unfiltered, sorted search" do

    setup do
      @combined_index = stub("unified index")
      @searcher = UnifiedSearcher.new(@combined_index, {}, {})
      @combined_index.expects(:raw_search).with({
        from: 0,
        size: 20,
        query: TIMESTAMP_EXISTS_WITH_CHEESE_QUERY,
        fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
        sort: [{"public_timestamp" => {order: "asc"}}],
      }).returns({
        "hits" => {"hits" => sample_docs, "total" => 3}
      })
      @combined_index.expects(:index_name).returns(
        "mainstream,detailed,government"
      )

      @results = @searcher.search({
        start: 0,
        count: 20,
        query: "cheese",
        order: ["public_timestamp", "asc"],
        filters: {},
        return_fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
      })
    end

    should "include results from all indexes" do
      assert_equal(
        ["government", "mainstream", "detailed"].to_set,
        @results[:results].map do |result|
          result[:index]
        end.to_set
      )
    end

    should "include total result count" do
      assert_equal(3, @results[:total])
    end
  end

  context "filtered, unsorted search" do

    setup do
      @combined_index = stub("unified index")
      @searcher = UnifiedSearcher.new(@combined_index, {}, {})
      @combined_index.expects(:raw_search).with({
        from: 0,
        size: 20,
        query: CHEESE_QUERY,
        filter: {"terms" => {"organisations" => ["ministry-of-magic"]}},
        fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
      }).returns({
        "hits" => {"hits" => sample_docs, "total" => 3}
      })
      @combined_index.expects(:index_name).returns(
        "mainstream,detailed,government"
      )

      @results = @searcher.search({
        start: 0,
        count: 20,
        query: "cheese",
        filters: {"organisations" => ["ministry-of-magic"]},
        return_fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
        facets: nil,
      })
    end

    should "include results from all indexes" do
      assert_equal(
        ["government", "mainstream", "detailed"].to_set,
        @results[:results].map do |result|
          result[:index]
        end.to_set
      )
    end

    should "include total result count" do
      assert_equal(3, @results[:total])
    end
  end

  context "faceted, unsorted search" do

    setup do
      @combined_index = stub("unified index")
      @searcher = UnifiedSearcher.new(@combined_index, {}, {})
      @combined_index.expects(:raw_search).with({
        from: 0,
        size: 20,
        query: CHEESE_QUERY,
        facets: {
          "organisations" => {
            terms: {
              field: "organisations",
              order: "count",
              size: 100000,
            }}},
        fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
      }).returns({
        "hits" => {"hits" => sample_docs, "total" => 3},
        "facets" => {"organisations" => {
          "missing" => 7,
          "terms" => [
            {"term" => "a", "count" => 2,},
            {"term" => "b", "count" => 1,},
          ]
        }},
      })
      @combined_index.expects(:index_name).returns(
        "mainstream,detailed,government"
      )

      @results = @searcher.search({
        start: 0,
        count: 20,
        query: "cheese",
        filters: {},
        return_fields: SearchParameterParser::ALLOWED_RETURN_FIELDS,
        facets: {"organisations" => 1},
      })
    end

    should "include results from all indexes" do
      assert_equal(
        ["government", "mainstream", "detailed"].to_set,
        @results[:results].map do |result|
          result[:index]
        end.to_set
      )
    end

    should "include total result count" do
      assert_equal(3, @results[:total])
    end

    should "include requested number of facet options" do
      facet = @results[:facets]["organisations"]
      assert_equal(1, facet[:options].length)
    end

    should "have correct top facet option" do
      facet = @results[:facets]["organisations"]
      assert_equal({value: "a", documents: 2}, facet[:options][0])
    end

    should "include requested number of facets" do
      facet = @results[:facets]["organisations"]
      assert_equal(2, facet[:total_options])
      assert_equal(1, facet[:missing_options])
    end

    should "include number of documents with no value" do
      facet = @results[:facets]["organisations"]
      assert_equal(7, facet[:documents_with_no_value])
    end
  end

end
