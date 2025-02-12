module Search
  class FormatMigrator
    def initialize(search_config, base_query: nil)
      @search_config = search_config
      @base_query = base_query
    end

    def call
      {
        bool: {
          minimum_should_match: 1,
          should: [excluding_formats, only_formats, migrated_publishing_apps].compact,
        },
      }
    end

  private

    attr_reader :search_config

    def migrated_indices
      search_config.new_content_index.real_index_names
    end

    def migrated_formats
      GovukIndex::MigratedFormats.migrated_formats.keys
    end

    def excluding_formats
      options = {}
      options[:must] = base_query

      options[:must_not] = if migrated_formats.any?
                             [
                               { terms: { _index: migrated_indices } },
                               { terms: { format: migrated_formats } },
                             ]
                           else
                             { terms: { _index: migrated_indices } }
                           end

      { bool: options }
    end

    def only_formats
      return { bool: { must_not: { match_all: {} } } } if migrated_formats.empty?

      {
        bool: {
          must: [
            base_query,
            { terms: { _index: migrated_indices } },
            { terms: { format: migrated_formats } },
          ],
        },
      }
    end

    def migrated_publishing_apps
      return nil if GovukIndex::MigratedFormats.migrated_publishing_apps.empty?

      {
        bool: {
          must: [
            base_query,
            { terms: { _index: migrated_indices } },
            { terms: { publishing_app: GovukIndex::MigratedFormats.migrated_publishing_apps } },
          ],
        },
      }
    end

    def base_query
      # {} isn't legal in a must
      if @base_query && @base_query != {}
        @base_query
      else
        { match_all: {} }
      end
    end
  end
end
