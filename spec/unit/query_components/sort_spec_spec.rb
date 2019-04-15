require 'spec_helper'

RSpec.describe 'SortTest' do
  context "without explicit ordering" do
    it "order by popularity" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new)

      result = builder.payload

      expect(result).to eq([{ "popularity" => { order: "desc" } }])
    end
  end

  context "with debug popularity off" do
    it "not explicitly order" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(debug: { disable_popularity: true }))

      result = builder.payload

      expect(result).to be_nil
    end
  end

  context "search with ascending sort" do
    it "put documents without a timestamp at the bottom" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(order: %w(public_timestamp asc)))

      result = builder.payload

      expect(result).to eq([{ "public_timestamp" => { order: "asc", missing: "_last", unmapped_type: "integer" } }])
    end
  end

  context "search with descending sort" do
    it "put documents without a timestamp at the bottom" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(order: %w(public_timestamp desc)))

      result = builder.payload

      expect(result).to eq([{ "public_timestamp" => { order: "desc", missing: "_last", unmapped_type: "integer" } }])
    end
  end

  context "more like this query" do
    it "not explicitly order" do
      builder = QueryComponents::Sort.new(Search::QueryParameters.new(similar_to: ["/hello-world"]))

      result = builder.payload

      expect(result).to be_nil
    end
  end
end
