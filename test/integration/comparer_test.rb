require "integration_test_helper"

class SearchTest < IntegrationTest
  def test_for_sort_ordering
    commit_document("mainstream_test", { some: 'data' }, id: 'ABC', type: "edition")
    commit_document("mainstream_test", { some: 'data' }, id: 'DEF', type: "other")
    commit_document("mainstream_test", { some: 'data' }, id: 'GHI', type: "edition")

    commit_document("government_test", { some: 'data' }, id: 'ABC', type: "edition")
    commit_document("government_test", { some: 'data' }, id: 'DEF', type: "other")
    commit_document("government_test", { some: 'data' }, id: 'GHI', type: "edition")

    get "/search"

    results = Indexer::CompareEnumerator.new('mainstream_test', 'government_test')

    assert_equal [
      [{ some: 'data', id: 'ABC', type: "edition" }, { some: 'data', id: 'ABC', type: "edition" }],
      [{ some: 'data', id: 'DEF', type: "other" }, { some: 'data', id: 'DEF', type: "other" }],
      [{ some: 'data', id: 'GHI', type: "edition" }, { some: 'data', id: 'GHI', type: "edition" }],
    ], results.to_a
  end
end
