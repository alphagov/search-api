require 'spec_helper'

RSpec.describe 'ComparerTest' do
  it "for sort ordering" do
    insert_document('govuk_test', { some: 'data' }, id: 'ABC', type: 'edition')
    insert_document('govuk_test', { some: 'data' }, id: 'DEF', type: 'hmrc_manual')
    commit_document('govuk_test', { some: 'data' }, id: 'GHI', type: 'edition')

    insert_document('government_test', { some: 'data' }, id: 'ABC', type: 'edition')
    insert_document('government_test', { some: 'data' }, id: 'DEF', type: 'edition')
    commit_document('government_test', { some: 'data' }, id: 'GHI', type: 'edition')

    results = Indexer::CompareEnumerator.new('govuk_test', 'government_test')

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

  it "only compares filtered formats" do
    insert_document('govuk_test', { some: 'data', format: 'edition' }, id: 'ABC', type: 'edition')
    insert_document('govuk_test', { some: 'data', format: 'other' }, id: 'DEF', type: 'hmrc_manual')
    commit_document('govuk_test', { some: 'data', format: 'other' }, id: 'GHI', type: 'edition')

    insert_document('government_test', { some: 'data', format: 'edition' }, id: 'ABC', type: 'edition')
    insert_document('government_test', { some: 'data', format: 'other' }, id: 'DEF', type: 'hmrc_manual')
    commit_document('government_test', { some: 'data', format: 'edition' }, id: 'GHI', type: 'edition')

    query = {
      query: {
        bool: {
          must: { match_all: {} },
          filter: { term: { format: 'edition' } }
        }
      }
    }
    results = Indexer::CompareEnumerator.new('govuk_test', 'government_test', query)

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

  it "comparison output works" do
    insert_document('govuk_test', { some: 'data', format: 'edition', field: 1 }, id: 'ABC', type: 'edition')
    insert_document('govuk_test', { some: 'data', format: 'other' }, id: 'DEF', type: 'other')
    commit_document('govuk_test', { some: 'data', format: 'other' }, id: 'GHI', type: 'edition')

    insert_document('government_test', { some: 'data', format: 'edition', field: 10 }, id: 'ABC', type: 'edition')
    insert_document('government_test', { some: 'data', format: 'other' }, id: 'DEF', type: 'other')
    commit_document('government_test', { some: 'data', format: 'edition' }, id: 'GHI', type: 'edition')

    comparer = Indexer::Comparer.new('govuk_test', 'government_test', filtered_format: 'edition', io: StringIO.new)

    expect(comparer.run).to eq(changed: 1, 'changes: field': 1, added_items: 1)
  end
end
