require "test_helper"
require 'indexer/comparer'

class ComparerTest < MiniTest::Unit::TestCase
  def test_can_detect_when_a_record_is_added
    setup_enumerator_response(Indexer::CompareEnumerator::NO_VALUE, { some: 'data' })

    comparer = Indexer::Comparer.new(
      'index_a',
      'index_b',
      io: StringIO.new
    )
    outcome = comparer.run
    assert_equal outcome, { added_items: 1 }
  end

  def test_can_detect_when_a_record_is_remove
    setup_enumerator_response({ some: 'data' }, Indexer::CompareEnumerator::NO_VALUE)

    comparer = Indexer::Comparer.new(
      'index_a',
      'index_b',
      io: StringIO.new
    )
    outcome = comparer.run
    assert_equal outcome, { removed_items: 1 }
  end

  def test_can_detect_when_a_record_has_changed
    setup_enumerator_response({ data: 'old' }, { data: 'new' })

    comparer = Indexer::Comparer.new(
      'index_a',
      'index_b',
      io: StringIO.new
    )
    outcome = comparer.run
    assert_equal outcome, { changed: 1, 'changes: data': 1 }
  end

  def test_can_detect_when_a_record_is_unchanged
    setup_enumerator_response({ data: 'some' }, { data: 'some' })

    comparer = Indexer::Comparer.new(
      'index_a',
      'index_b',
      io: StringIO.new
    )
    outcome = comparer.run
    assert_equal outcome, { unchanged: 1 }
  end

  def test_can_detect_when_a_record_is_unchanged_apart_from_ignored_fields
    setup_enumerator_response({ data: 'some', ignore: 'me' }, { data: 'some' })

    comparer = Indexer::Comparer.new(
      'index_a',
      'index_b',
      ignore: [:ignore],
      io: StringIO.new
    )
    outcome = comparer.run
    assert_equal outcome, { unchanged: 1 }
  end

  def test_can_detect_when_a_record_is_unchanged_apart_from_default_ignored_fields
    setup_enumerator_response({ data: 'some', 'popularity' => '100' }, { data: 'some' })

    comparer = Indexer::Comparer.new(
      'index_a',
      'index_b',
      io: StringIO.new
    )
    outcome = comparer.run
    assert_equal outcome, { unchanged: 1 }
  end

  def test_matches_are_only_valid_on_the_same_filter_set
    setup_filters('format', ['publication', 'announcement'])
    setup_compare_enumerator(
      'index_a',
      'index_b',
      ['format', 'publication'] => [[{ data: 'here' }, Indexer::CompareEnumerator::NO_VALUE]],
      ['format', 'announcement'] => [[Indexer::CompareEnumerator::NO_VALUE, { data: 'here' }]],
    )

    comparer = Indexer::Comparer.new(
      'index_a',
      'index_b',
      io: StringIO.new
    )
    outcome = comparer.run
    assert_equal outcome, { removed_items: 1, added_items: 1 }
  end

private

  def setup_enumerator_response(left, right)
    setup_filters('format', ['publication'])
    setup_compare_enumerator(
      'index_a',
      'index_b',
      ['format', 'publication'] => [[left, right]],
    )
  end

  def setup_filters(filter_field, filer_values)
    search_config = stub(:search_config)
    SearchConfig.stubs(:new).returns(search_config)

    response = {
      aggregates: {
        filter_field => {
          options: filer_values.map do |filter_value|
            { value: { "slug" => filter_value } }
          end
        }
      }
    }

    search_config.stubs(:run_search).returns(response)
  end

  def setup_compare_enumerator(index_a, index_b, config)
    config.each do |(filter_field, filter_value), data|
      Indexer::CompareEnumerator.stubs(:new).with(
        index_a, index_b, { query: { term: { filter_field => filter_value } } }
      ).returns(data.to_enum)
    end
  end
end
