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

    # ordered by type and the ID
    assert_equal [
      [
        { 'some' => 'data', '_root_id' => 'ABC', '_root_type' => "edition" },
        { 'some' => 'data', '_root_id' => 'ABC', '_root_type' => "edition" },
      ],
      [
        { 'some' => 'data', '_root_id' => 'GHI', '_root_type' => "edition" },
        { 'some' => 'data', '_root_id' => 'GHI', '_root_type' => "edition" },
      ],
      [
        { 'some' => 'data', '_root_id' => 'DEF', '_root_type' => "other" },
        { 'some' => 'data', '_root_id' => 'DEF', '_root_type' => "other" },
      ],
    ], results.to_a
  end
end
