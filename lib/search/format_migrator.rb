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
          # match documents meeting any of below conditions
          # this query excludes documents that are present in the migrated index, but their format is not yet marked as migrated
          should: [be_an_unmigrated_document, be_a_migrated_document].compact,
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

    # This condition captures documents that have not been migrated to the new index
    def be_an_unmigrated_document
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

    # This condition captures documents that have been migrated to the new index
    def be_a_migrated_document
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
