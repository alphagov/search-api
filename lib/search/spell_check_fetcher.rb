require_relative 'query_components/suggest'
require_relative 'suggestion_blacklist'

# Elasticsearch tries to find spelling suggestions for words that don't occur
# in our content, as they are probably mispelled. However, currently it is
# returning suggestions for words that do not occur in *every* index. Because
# the `service-manual` index contains very few words, elasticsearch returns
# too many spelling suggestions for common terms. For example, using the
# suggester on all four indices will yield a suggestion for "PAYE", because
# it's mentioned only in the `government` index, and not the `service-manual`
# index.
#
# This issue is mentioned in
# https://github.com/elastic/elasticsearch/issues/7472.
#
# Our solution is to run a separate query to fetch the suggestions, only using
# the indices we want.
module Search
  SpellCheckFetcher = Struct.new(:search_params, :registries) do
    def es_response
      return unless should_correct_query?
      search_client.raw_search(elasticsearch_query)['suggest']
    end

  private

    def should_correct_query?
      SuggestionBlacklist.new(registries).should_correct?(search_params.query)
    end

    def search_client
      Rummager.search_config.search_server.index_for_search(spelling_index_names)
    end

    def elasticsearch_query
      {
        size: 0,
        suggest: QueryComponents::Suggest.new(search_params).payload
      }
    end

    def spelling_index_names
      Rummager.search_config.spelling_index_names
    end
  end
end
