require "test_helper"
require 'indexer/comparer'

class ComparerTest < Minitest::Test
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

  def test_can_detect_when_a_record_is_removed
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

private

  def setup_enumerator_response(left, right)
    Indexer::CompareEnumerator.stubs(:new).with(
      'index_a',
      'index_b',
    ).returns([[left, right]].to_enum)
  end
end
