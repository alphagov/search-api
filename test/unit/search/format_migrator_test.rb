require 'test_helper'

class FormatMigratorTest < Minitest::Test
  def test_when_base_query_without_migrated_formats
    GovukIndex::MigratedFormats.stubs(:migrated_formats).returns([])
    base_query = { filter: 'component' }
    expected = {
      indices: {
        indices: %w(mainstream detailed government),
        filter: {
          bool: { should: [base_query] }
        },
        no_match_filter: 'none'
      }
    }
    assert_equal expected, Search::FormatMigrator.new(base_query).call
  end

  def test_when_base_query_with_migrated_formats
    GovukIndex::MigratedFormats.stubs(:migrated_formats).returns(['help_page'])
    base_query = { filter: 'component' }
    expected = {
      indices: {
        indices: %w(mainstream detailed government),
        filter: {
          bool: {
            should: [base_query],
            must_not: { terms: { format: ['help_page'] } },
          }
        },
        no_match_filter: {
          bool: {
            should: [base_query],
            must: { terms: { format: ['help_page'] } },
          }
        }
      }
    }
    assert_equal expected, Search::FormatMigrator.new(base_query).call
  end

  def test_when_no_base_query_without_migrated_formats
    GovukIndex::MigratedFormats.stubs(:migrated_formats).returns([])
    expected = {
      indices: {
        indices: %w(mainstream detailed government),
        filter: {},
        no_match_filter: 'none'
      }
    }
    assert_equal expected, Search::FormatMigrator.new(nil).call
  end

  def test_when_no_base_query_with_migrated_formats
    GovukIndex::MigratedFormats.stubs(:migrated_formats).returns(['help_page'])
    expected = {
      indices: {
        indices: %w(mainstream detailed government),
        filter: {
          bool: {
            must_not: { terms: { format: ['help_page'] } },
          }
        },
        no_match_filter: {
          bool: {
            must: { terms: { format: ['help_page'] } },
          }
        }
      }
    }
    assert_equal expected, Search::FormatMigrator.new(nil).call
  end
end
