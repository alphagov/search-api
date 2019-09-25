require "spec_helper"

RSpec.describe "ScrollEnumeratorTest" do
  it "returns expected results for unsorted search" do
    10.times.each do |id|
      commit_document("govuk_test", { some: "data" }, id: "id-#{id}", type: "edition")
    end

    results = ScrollEnumerator.new(
      client: client,
      index_names: "govuk_test",
      search_body: { query: { match_all: {} } },
      batch_size: 4,
    ) { |d| d }

    expect(results.count).to eq(10)
  end

  it "returns expected results for sorted search" do
    10.times.each do |id|
      commit_document("govuk_test", { some: "data" }, id: "id-#{id}", type: "edition")
    end

    results = ScrollEnumerator.new(
      client: client,
      index_names: "govuk_test",
      search_body: { query: { match_all: {} }, sort: [{ _uid: { order: "asc" } }] },
      batch_size: 4,
    ) { |d| d }

    expect(results.count).to eq(10)
  end

  it "returns expected results when empty result set" do
    results = ScrollEnumerator.new(
      client: client,
      index_names: "govuk_test",
      search_body: { query: { match_all: {} } },
      batch_size: 4,
    ) { |d| d }

    expect(results.count).to eq(0)
  end
end
