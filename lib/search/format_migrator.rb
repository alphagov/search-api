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
          should: [excluding_formats, only_formats],
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

      if migrated_formats.any?
        options[:must_not] = [
          { terms: { _index: migrated_indices } },
          { terms: { format: migrated_formats } },
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
            base_query,
            { terms: { _index: migrated_indices } },
            { terms: { format: migrated_formats } },
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
