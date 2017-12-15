require 'spec_helper'

RSpec.describe Search::FormatMigrator do
  it "when_base_query_without_migrated_formats" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return({})
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
    expect(described_class.new(base_query).call).to eq(expected)
  end

  it "when_base_query_with_migrated_formats" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return('help_page' => :all)
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
    expect(described_class.new(base_query).call).to eq(expected)
  end

  it "when_no_base_query_without_migrated_formats" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return({})
    expected = {
      indices: {
        indices: %w(mainstream_test government_test),
        filter: {},
        no_match_filter: 'none'
      }
    }
    expect(described_class.new(nil).call).to eq(expected)
  end

  it "when_no_base_query_with_migrated_formats" do
    allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return('help_page' => :all)
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
    expect(described_class.new(nil).call).to eq(expected)
  end
end
