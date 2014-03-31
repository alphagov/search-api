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

  context "unfiltered, unsorted search" do

    setup do
      @combined_index = stub("unified index")
      @searcher = UnifiedSearcher.new(@combined_index, {})
      @combined_index.expects(:raw_search).with({
        from: 0,
        size: 20,
        query: CHEESE_QUERY,
        fields: UnifiedSearchBuilder::ALLOWED_RETURN_FIELDS,
      }).returns({
        "hits" => {"hits" => sample_docs, "total" => 3}
      })
      @combined_index.expects(:index_name).returns(
        "mainstream,detailed,government"
      )

      @results = @searcher.search(0, 20, "cheese", nil, {})
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

  context "unfiltered, sorted search" do

    setup do
      @combined_index = stub("unified index")
      @searcher = UnifiedSearcher.new(@combined_index, {})
      @combined_index.expects(:raw_search).with({
        from: 0,
        size: 20,
        query: CHEESE_QUERY,
        fields: UnifiedSearchBuilder::ALLOWED_RETURN_FIELDS,
        filter: {'exists' => {'field' => 'public_timestamp'}},
        sort: [{"public_timestamp" => {order: "asc"}}],
      }).returns({
        "hits" => {"hits" => sample_docs, "total" => 3}
      })
      @combined_index.expects(:index_name).returns(
        "mainstream,detailed,government"
      )

      @results = @searcher.search(0, 20, "cheese", "public_timestamp", {})
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
      @searcher = UnifiedSearcher.new(@combined_index, {})
      @combined_index.expects(:raw_search).with({
        from: 0,
        size: 20,
        query: CHEESE_QUERY,
        filter: {"terms" => {"organisations" => ["ministry-of-magic"]}},
        fields: UnifiedSearchBuilder::ALLOWED_RETURN_FIELDS,
      }).returns({
        "hits" => {"hits" => sample_docs, "total" => 3}
      })
      @combined_index.expects(:index_name).returns(
        "mainstream,detailed,government"
      )

      @results = @searcher.search(0, 20, "cheese", nil,
        {"organisations" => ["ministry-of-magic"]})
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
end
