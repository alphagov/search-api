require 'spec_helper'

RSpec.describe Search::FormatMigrator do
  it "when_base_query_without_migrated_formats" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return([])
    base_query = { filter: 'component' }
    expected = {
      indices: {
        indices: %w(mainstream_test government_test),
        filter: {
          bool: { should: [base_query] }
        },
        no_match_filter: 'none'
      }
    }
    expect(expected).to eq(described_class.new(base_query).call)
  end

  it "when_base_query_with_migrated_formats" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return(['help_page'])
    base_query = { filter: 'component' }
    expected = {
      indices: {
        indices: %w(mainstream_test government_test),
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
    expect(expected).to eq(described_class.new(base_query).call)
  end

  it "when_no_base_query_without_migrated_formats" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return([])
    expected = {
      indices: {
        indices: %w(mainstream_test government_test),
        filter: {},
        no_match_filter: 'none'
      }
    }
    expect(expected).to eq(described_class.new(nil).call)
  end

  it "when_no_base_query_with_migrated_formats" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return(['help_page'])
    expected = {
      indices: {
        indices: %w(mainstream_test government_test),
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
    expect(expected).to eq(described_class.new(nil).call)
  end
end
