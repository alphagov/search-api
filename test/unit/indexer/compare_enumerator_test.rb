require "test_helper"
require 'indexer/compare_enumerator'
require "support/integration_test"

class CompareEnumeratorTest < Minitest::Test
  def test_when_matching_keys_exist
    data_left = { '_root_id' => 'abc', '_root_type' => 'stuff', 'custom' => 'data_left' }
    data_right = { '_root_id' => 'abc', '_root_type' => 'stuff', 'custom' => 'data_right' }

    stub_scroll_enumerator(left_request: [data_left], right_request: [data_right])

    results = Indexer::CompareEnumerator.new('index_a', 'index_b').to_a
    assert_equal results, [[data_left, data_right]]
  end

  def test_when_key_only_exists_in_left_index
    data = { '_root_id' => 'abc', '_root_type' => 'stuff', 'custom' => 'data_left' }

    stub_scroll_enumerator(left_request: [data], right_request: [])

    results = Indexer::CompareEnumerator.new('index_a', 'index_b').to_a
    assert_equal results, [[data, Indexer::CompareEnumerator::NO_VALUE]]
  end


  def test_when_key_only_exists_in_right_index
    data = { '_root_id' => 'abc', '_root_type' => 'stuff', 'custom' => 'data_right' }

    stub_scroll_enumerator(left_request: [], right_request: [data])

    results = Indexer::CompareEnumerator.new('index_a', 'index_b').to_a
    assert_equal results, [[Indexer::CompareEnumerator::NO_VALUE, data]]
  end

  def test_with_matching_ids_but_different_types
    data_left = { '_root_id' => 'abc', '_root_type' => 'stuff', 'custom' => 'data_left' }
    data_right = { '_root_id' => 'abc', '_root_type' => 'other_stuff', 'custom' => 'data_right' }

    stub_scroll_enumerator(left_request: [data_left], right_request: [data_right])

    results = Indexer::CompareEnumerator.new('index_a', 'index_b').to_a
    assert_equal results, [
      [Indexer::CompareEnumerator::NO_VALUE, data_right],
      [data_left, Indexer::CompareEnumerator::NO_VALUE],
    ]
  end

  def test_with_different_ids
    data_left = { '_root_id' => 'abc', '_root_type' => 'stuff', 'custom' => 'data_left' }
    data_right = { '_root_id' => 'def', '_root_type' => 'stuff', 'custom' => 'data_right' }

    stub_scroll_enumerator(left_request: [data_left], right_request: [data_right])

    results = Indexer::CompareEnumerator.new('index_a', 'index_b').to_a
    assert_equal results, [
      [data_left, Indexer::CompareEnumerator::NO_VALUE],
      [Indexer::CompareEnumerator::NO_VALUE, data_right],
    ]
  end

  def test_correct_aligns_records_with_matching_keys
    key1 = { '_root_id' => 'abc', '_root_type' => 'stuff' }
    key2 = { '_root_id' => 'def', '_root_type' => 'stuff' }
    key3 = { '_root_id' => 'ghi', '_root_type' => 'stuff' }
    key4 = { '_root_id' => 'jkl', '_root_type' => 'stuff' }
    key5 = { '_root_id' => 'mno', '_root_type' => 'stuff' }

    stub_scroll_enumerator(left_request: [key1, key3, key5], right_request: [key2, key3, key4, key5])

    results = Indexer::CompareEnumerator.new('index_a', 'index_b').to_a
    assert_equal results, [
      [key1, Indexer::CompareEnumerator::NO_VALUE],
      [Indexer::CompareEnumerator::NO_VALUE, key2],
      [key3, key3],
      [Indexer::CompareEnumerator::NO_VALUE, key4],
      [key5, key5],
    ]
  end

  def test_scroll_enumerator_mappings
    data = { '_id' => 'abc', '_type' => 'stuff', '_source' => { 'custom' => 'data' } }
    stub_client_for_scroll_enumerator(return_values: [[data], []])

    enum = Indexer::CompareEnumerator.new('index_a', 'index_b').get_enum('index_name')

    assert_equal enum.to_a, [
      { '_root_id' => 'abc', '_root_type' => 'stuff', 'custom' => 'data' }
    ]
  end

  def test_scroll_enumerator_mappings_when_filter_is_passed_in
    data = { '_id' => 'abc', '_type' => 'stuff', '_source' => { 'custom' => 'data' } }
    search_body = { query: 'custom_filter', sort: 'by_stuff' }

    stub_client_for_scroll_enumerator(return_values: [[data], []], search_body: search_body)

    enum = Indexer::CompareEnumerator.new('index_a', 'index_b').get_enum('index_name', search_body)

    assert_equal enum.to_a, [
      { '_root_id' => 'abc', '_root_type' => 'stuff', 'custom' => 'data' }
    ]
  end

  def test_scroll_enumerator_mappings_without_sorting
    data = { '_id' => 'abc', '_type' => 'stuff', '_source' => { 'custom' => 'data' } }
    search_body = { query: 'custom_filter' }

    stub_client_for_scroll_enumerator(return_values: [[data], []], search_body: search_body.merge(sort: Indexer::CompareEnumerator::DEFAULT_SORT))

    enum = Indexer::CompareEnumerator.new('index_a', 'index_b').get_enum('index_name', search_body)

    assert_equal enum.to_a, [
      { '_root_id' => 'abc', '_root_type' => 'stuff', 'custom' => 'data' }
    ]
  end

private

  def commit_document(*args)
    IntegrationTest.new(nil).commit_document(*args)
  end

  def stub_scroll_enumerator(left_request:, right_request:)
    ScrollEnumerator.stubs(:new).returns(
      left_request.to_enum,
      right_request.to_enum,
    )
  end

  def stub_client_for_scroll_enumerator(return_values:, search_body: nil, search_type: "query_then_fetch")
    client = stub(:client)
    Services.stubs(:elasticsearch).returns(client)

    client.expects(:search).with(
      has_entries(
        index: 'index_name',
        search_type: search_type,
        body: search_body || {
          query: Indexer::CompareEnumerator::DEFAULT_QUERY,
          sort: Indexer::CompareEnumerator::DEFAULT_SORT,
        }
      )
    ).returns(
      { '_scroll_id' => 'scroll_ID_0', 'hits' => { 'total' => 1, 'hits' => return_values[0] } }
    )


    return_values[1..-1].each_with_index do |return_value, i|
      client.expects(:scroll).with(
        scroll_id: "scroll_ID_#{i}", scroll: "1m"
      ).returns(
        { '_scroll_id' => "scroll_ID_#{i + 1}", 'hits' => { 'hits' => return_value } }
      )
    end
  end
end
