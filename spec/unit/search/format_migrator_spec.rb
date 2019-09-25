require "spec_helper"

RSpec.describe Search::FormatMigrator do
  # rubocop:disable RSpec/AnyInstance
  before do
    allow_any_instance_of(LegacyClient::IndexForSearch).to receive(:real_index_names).and_return(%w(govuk_test))
  end
  # rubocop:enable RSpec/AnyInstance
  context "with every cluster" do
    Clusters.active.each do |cluster|
      it "when base query without migrated formats" do
        allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return({})
        base_query = { filter: "component" }
        expected = {
          bool: {
            minimum_should_match: 1,
            should: [
              {
                bool: {
                  must: base_query,
                  must_not: { terms: { _index: %w(govuk_test) } },
                },
              },
              {
                bool: {
                  must_not: { match_all: {} },
                },
              }
            ],
          },
        }
        expect(described_class.new(
          SearchConfig.default_instance,
          base_query: base_query,
        ).call).to eq(expected)
      end

      it "when base query with migrated formats" do
        allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return("help_page" => :all)
        base_query = { filter: "component" }
        expected = {
          bool: {
            minimum_should_match: 1,
            should: [
              {
                bool: {
                  must: base_query,
                  must_not: [
                    { terms: { _index: %w(govuk_test) } },
                    { terms: { format: %w(help_page) } }
                  ],
                },
              },
              {
                bool: {
                  must: [
                    base_query,
                    { terms: { _index: %w(govuk_test) } },
                    { terms: { format: %w(help_page) } }
                  ],
                },
              }
            ],
          },
        }
        expect(described_class.new(
          SearchConfig.default_instance,
          base_query: base_query,
        ).call).to eq(expected)
      end

      it "when no base query without migrated formats" do
        allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return({})
        expected = {
          bool: {
            minimum_should_match: 1,
            should: [
              {
                bool: {
                  must: { match_all: {} },
                  must_not: { terms: { _index: %w(govuk_test) } },
                },
              },
              { bool: { must_not: { match_all: {} } } }
            ],
          },
        }
        expect(described_class.new(
          SearchConfig.default_instance,
        ).call).to eq(expected)
      end

      it "when no base query with migrated formats" do
        allow(GovukIndex::MigratedFormats).to receive(:migrated_formats).and_return("help_page" => :all)
        expected = {
          bool:
          { minimum_should_match: 1,
            should: [
              {
                bool: {
                  must: { match_all: {} },
                  must_not: [
                    { terms: { _index: %w(govuk_test) } },
                    { terms: { format: %w(help_page) } }
                  ],
                },
              },
              {
                bool: {
                  must: [
                    { match_all: {} },
                    { terms: { _index: %w(govuk_test) } },
                    { terms: { format: %w(help_page) } }
                  ],
                },
              }
            ],
          },
        }
        expect(described_class.new(
          SearchConfig.default_instance,
        ).call).to eq(expected)
      end
    end
  end
end
