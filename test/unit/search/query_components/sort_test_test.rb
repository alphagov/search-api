require 'test_helper'

class SortTest < ShouldaUnitTestCase
  context "without explicit ordering" do
    should "order by popularity" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new)

      result = builder.payload

      assert_equal result, [{ "popularity" => { order: "desc" } }]
    end
  end

  context "with debug popularity off" do
    should "not explicitly order" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(debug: { disable_popularity: true }))

      result = builder.payload

      assert_nil result
    end
  end

  context "search with ascending sort" do
    should "put documents without a timestamp at the bottom" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(order: %w(public_timestamp asc)))

      result = builder.payload

      assert_equal(
        [{ "public_timestamp" => { order: "asc", missing: "_last" } }],
        result
      )
    end
  end

  context "search with descending sort" do
    should "put documents without a timestamp at the bottom" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(order: %w(public_timestamp desc)))

      result = builder.payload

      assert_equal(
        [{ "public_timestamp" => { order: "desc", missing: "_last" } }],
        result
      )
    end
  end

  context "more like this query" do
    should "not explicitly order" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(similar_to: ["/hello-world"]))

      result = builder.payload

      assert_nil result
    end
  end
end
