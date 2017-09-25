require 'spec_helper'

RSpec.describe 'SortTest', tags: ['shoulda'] do
  context "without explicit ordering" do
    it "order by popularity" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new)

      result = builder.payload

      assert_equal result, [{ "popularity" => { order: "desc" } }]
    end
  end

  context "with debug popularity off" do
    it "not explicitly order" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(debug: { disable_popularity: true }))

      result = builder.payload

      assert_nil result
    end
  end

  context "search with ascending sort" do
    it "put documents without a timestamp at the bottom" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(order: %w(public_timestamp asc)))

      result = builder.payload

      assert_equal(
        [{ "public_timestamp" => { order: "asc", missing: "_last" } }],
        result
      )
    end
  end

  context "search with descending sort" do
    it "put documents without a timestamp at the bottom" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(order: %w(public_timestamp desc)))

      result = builder.payload

      assert_equal(
        [{ "public_timestamp" => { order: "desc", missing: "_last" } }],
        result
      )
    end
  end

  context "more like this query" do
    it "not explicitly order" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(similar_to: ["/hello-world"]))

      result = builder.payload

      assert_nil result
    end
  end
end
