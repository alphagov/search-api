require 'spec_helper'

RSpec.describe 'ScrollEnumeratorTest' do
  it "returns_expected_results_for_unsorted_search" do
    10.times.each do |id|
      commit_document("mainstream_test", { some: 'data' }, id: "id-#{id}", type: "edition")
    end

    results = ScrollEnumerator.new(
      client: client,
      index_names: 'mainstream_test',
      search_body: { query: { match_all: {} } },
      batch_size: 4
    ) { |d| d }

    expect(results.count).to eq(10)
  end

  it "returns_expected_results_for_sorted_search" do
    10.times.each do |id|
      commit_document("mainstream_test", { some: 'data' }, id: "id-#{id}", type: "edition")
    end

    results = ScrollEnumerator.new(
      client: client,
      index_names: 'mainstream_test',
      search_body: { query: { match_all: {} }, sort: [{ _uid: { order: 'asc' } }] },
      batch_size: 4
    ) { |d| d }

    expect(results.count).to eq(10)
  end

  it "returns_expected_results_when_empty_result_set" do
    results = ScrollEnumerator.new(
      client: client,
      index_names: 'mainstream_test',
      search_body: { query: { match_all: {} } },
      batch_size: 4
    ) { |d| d }

    expect(results.count).to eq(0)
  end
end
