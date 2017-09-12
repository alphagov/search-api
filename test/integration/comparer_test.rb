require 'integration_test_helper'

class SearchTest < IntegrationTest
  def test_for_sort_ordering
    commit_document("mainstream_test", { some: 'data' }, id: 'ABC', type: "edition")
    commit_document("mainstream_test", { some: 'data' }, id: 'DEF', type: "hmrc_manual")
    commit_document("mainstream_test", { some: 'data' }, id: 'GHI', type: "edition")

    commit_document("government_test", { some: 'data' }, id: 'ABC', type: "edition")
    commit_document("government_test", { some: 'data' }, id: 'DEF', type: "edition")
    commit_document("government_test", { some: 'data' }, id: 'GHI', type: "edition")

    get "/search"

    results = Indexer::CompareEnumerator.new('mainstream_test', 'government_test')

    # ordered by type and the ID
    assert_equal [
      [
        { 'some' => 'data', '_root_id' => 'ABC', '_root_type' => "edition", 'link' => 'ABC' },
        { 'some' => 'data', '_root_id' => 'ABC', '_root_type' => "edition", 'link' => 'ABC' },
      ],
      [
        :__no_value_found__,
        { 'some' => 'data', '_root_id' => 'DEF', '_root_type' => "edition", 'link' => 'DEF' },
      ],
      [
        { 'some' => 'data', '_root_id' => 'GHI', '_root_type' => "edition", 'link' => 'GHI' },
        { 'some' => 'data', '_root_id' => 'GHI', '_root_type' => "edition", 'link' => 'GHI' },
      ],
      [
        { 'some' => 'data', '_root_id' => 'DEF', '_root_type' => "hmrc_manual", 'link' => 'DEF' },
        :__no_value_found__,
      ],
    ], results.to_a
  end
end
