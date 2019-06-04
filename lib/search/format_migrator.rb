module Search
  class FormatMigrator
    def initialize(base = nil)
      @base = base
    end

    def call
      {
        bool: {
          minimum_should_match: 1,
          should: [excluding_formats, only_formats]
        }
      }
    end

    def migrated_indices
      SearchConfig.instance.new_content_index.real_index_names
    end

    def migrated_formats
      GovukIndex::MigratedFormats.migrated_formats.keys
    end

  private

    def excluding_formats
      options = {}
      options[:must] = base

      if migrated_formats.any?
        options[:must_not] = [
          { terms: { _index: migrated_indices } },
          { terms: { format: migrated_formats } }
        ]
      else
        options[:must_not] = { terms: { _index: migrated_indices } }
      end

      { bool: options }
    end

    def only_formats
      return { bool: { must_not: { match_all: {} } } } if migrated_formats.empty?

      {
        bool: {
          must: [
            base,
            { terms: { _index: migrated_indices } },
            { terms: { format: migrated_formats } }
          ],
        },
      }
    end

    def base
      # {} isn't legal in a must
      if @base && @base != {}
        @base
      else
        { match_all: {} }
      end
    end
  end
end
