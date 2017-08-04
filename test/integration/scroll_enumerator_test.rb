require 'integration_test_helper'

class ScrollEnumeratorTest < IntegrationTest
  def test_returns_expected_results_for_unsorted_search
    10.times.each do |id|
      commit_document("mainstream_test", { some: 'data' }, id: "id-#{id}", type: "edition")
    end

    results = ScrollEnumerator.new(
      client: client,
      index_names: 'mainstream_test',
      search_body: { query: { match_all: {} } },
      batch_size: 4
    ) { |d| d }

    assert_equal results.count, 10
  end

  def test_returns_expected_results_for_sorted_search
    10.times.each do |id|
      commit_document("mainstream_test", { some: 'data' }, id: "id-#{id}", type: "edition")
    end

    results = ScrollEnumerator.new(
      client: client,
      index_names: 'mainstream_test',
      search_body: { query: { match_all: {} }, sort: [{ _uid: { order: 'asc' } }] },
      batch_size: 4
    ) { |d| d }

    assert_equal results.count, 10
  end

  def test_returns_expected_results_when_empty_result_set
    results = ScrollEnumerator.new(
      client: client,
      index_names: 'mainstream_test',
      search_body: { query: { match_all: {} } },
      batch_size: 4
    ) { |d| d }

    assert_equal results.count, 0
  end
end
