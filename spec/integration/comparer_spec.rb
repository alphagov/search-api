require 'spec_helper'

RSpec.describe 'ComparerTest' do
  it "for_sort_ordering" do
    insert_document('mainstream_test', { some: 'data' }, id: 'ABC', type: 'edition')
    insert_document('mainstream_test', { some: 'data' }, id: 'DEF', type: 'hmrc_manual')
    commit_document('mainstream_test', { some: 'data' }, id: 'GHI', type: 'edition')

    insert_document('government_test', { some: 'data' }, id: 'ABC', type: 'edition')
    insert_document('government_test', { some: 'data' }, id: 'DEF', type: 'edition')
    commit_document('government_test', { some: 'data' }, id: 'GHI', type: 'edition')

    results = Indexer::CompareEnumerator.new('mainstream_test', 'government_test')

    # ordered by type and the ID
    expect([
      [
        { 'some' => 'data', '_root_id' => 'ABC', '_root_type' => 'edition', 'link' => 'ABC' },
        { 'some' => 'data', '_root_id' => 'ABC', '_root_type' => 'edition', 'link' => 'ABC' },
      ],
      [
        :__no_value_found__,
        { 'some' => 'data', '_root_id' => 'DEF', '_root_type' => 'edition', 'link' => 'DEF' },
      ],
      [
        { 'some' => 'data', '_root_id' => 'GHI', '_root_type' => 'edition', 'link' => 'GHI' },
        { 'some' => 'data', '_root_id' => 'GHI', '_root_type' => 'edition', 'link' => 'GHI' },
      ],
      [
        { 'some' => 'data', '_root_id' => 'DEF', '_root_type' => 'hmrc_manual', 'link' => 'DEF' },
        :__no_value_found__,
      ],
    ]).to eq results.to_a
  end

  it "only_compares_filtered_formats" do
    insert_document('mainstream_test', { some: 'data', format: 'edition' }, id: 'ABC', type: 'edition')
    insert_document('mainstream_test', { some: 'data', format: 'other' }, id: 'DEF', type: 'hmrc_manual')
    commit_document('mainstream_test', { some: 'data', format: 'other' }, id: 'GHI', type: 'edition')

    insert_document('government_test', { some: 'data', format: 'edition' }, id: 'ABC', type: 'edition')
    insert_document('government_test', { some: 'data', format: 'other' }, id: 'DEF', type: 'hmrc_manual')
    commit_document('government_test', { some: 'data', format: 'edition' }, id: 'GHI', type: 'edition')

    query = { filter: { term: { format: 'edition' } } }
    results = Indexer::CompareEnumerator.new('mainstream_test', 'government_test', query)

    expect([
      [
        { 'some' => 'data', '_root_id' => 'ABC', '_root_type' => 'edition', 'format' => 'edition', 'link' => 'ABC' },
        { 'some' => 'data', '_root_id' => 'ABC', '_root_type' => 'edition', 'format' => 'edition', 'link' => 'ABC' },
      ],
      [
        :__no_value_found__,
        { 'some' => 'data', '_root_id' => 'GHI', '_root_type' => 'edition', 'format' => 'edition', 'link' => 'GHI' },
      ],
    ]).to eq results.to_a
  end

  it "comparison_output_works" do
    insert_document('mainstream_test', { some: 'data', format: 'edition', field: 1 }, id: 'ABC', type: 'edition')
    insert_document('mainstream_test', { some: 'data', format: 'other' }, id: 'DEF', type: 'other')
    commit_document('mainstream_test', { some: 'data', format: 'other' }, id: 'GHI', type: 'edition')

    insert_document('government_test', { some: 'data', format: 'edition', field: 10 }, id: 'ABC', type: 'edition')
    insert_document('government_test', { some: 'data', format: 'other' }, id: 'DEF', type: 'other')
    commit_document('government_test', { some: 'data', format: 'edition' }, id: 'GHI', type: 'edition')

    comparer = Indexer::Comparer.new('mainstream_test', 'government_test', filtered_format: 'edition', io: StringIO.new)

    expect(comparer.run).to eq(changed: 1, 'changes: field': 1, added_items: 1)
  end
end
