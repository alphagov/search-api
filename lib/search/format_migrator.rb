module Search
  class FormatMigrator
    def initialize(base = nil)
      @base = base
    end

    def call
      {
        indices: {
          indices: SearchConfig.instance.content_index_names,
          query: excluding_formats,
          no_match_query: only_formats
        }
      }
    end

    def migrated_formats
      GovukIndex::MigratedFormats.migrated_formats.keys
    end

  private

    def excluding_formats
      options = {}
      options[:must] = @base if @base
      options[:must_not] = { terms: { format: migrated_formats } } if migrated_formats.any?
      { bool: options.any? ? options : { must: { match_all: {} } } }
    end

    def only_formats
      return 'none' if migrated_formats.empty?
      {
        bool: {
          must:
            if @base
              [@base, { terms: { format: migrated_formats } }]
            else
              { terms: { format: migrated_formats } }
            end
        },
      }
    end
  end
end
