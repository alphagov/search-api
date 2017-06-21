# Performs a search across all indices used for the GOV.UK site search

require_relative "aggregate_example_fetcher"
require_relative "query_builder"
require_relative "presenters/result_set_presenter"
require_relative 'query_components/suggest'
require_relative 'suggestion_blacklist'

module Search
  class Query
    attr_reader :index, :registries, :spelling_index, :suggestion_blacklist

    def initialize(index, registries, metasearch_index:, spelling_index:)
      @index = index
      @registries = registries
      @metasearch_index = metasearch_index
      @spelling_index = spelling_index
      @suggestion_blacklist = SuggestionBlacklist.new(registries)
    end

    # Search and combine the indices and return a hash of ResultSet objects
    def run(search_params)
      builder = QueryBuilder.new(
        search_params: search_params,
        content_index_names: content_index_names,
        metasearch_index: metasearch_index
      )

      payload = builder.payload
      es_response = index.raw_search(payload)

      example_fetcher = AggregateExampleFetcher.new(index, es_response, search_params, builder)
      aggregate_examples = example_fetcher.fetch

      # Augment the response with the suggest result from a separate query.
      if search_params.suggest_spelling?
        es_response['suggest'] = run_spell_checks(search_params)
      end

      ResultSetPresenter.new(
        search_params: search_params,
        es_response: es_response,
        registries: registries,
        aggregate_examples: aggregate_examples,
        schema: index.schema,
        query_payload: payload
      ).present
    end

    # Elasticsearch tries to find spelling suggestions for words that don't occur in
    # our content, as they are probably mispelled. However, currently it is
    # returning suggestions for words that do not occur in *every* index. Because
    # some indexes contain very few words, Elasticsearch returns too many spelling
    # suggestions for common terms. For example, using the suggester on all indices
    # will yield a suggestion for "PAYE", because it's mentioned only in the
    # `government` index, and not in other indexes.
    #
    # This issue is mentioned in
    # https://github.com/elastic/elasticsearch/issues/7472.
    #
    # Our solution is to run a separate query to fetch the suggestions, only using
    # the indices we want.
    def run_spell_checks(search_params)
      return unless suggestion_blacklist.should_correct?(search_params.query)

      query = {
        size: 0,
        suggest: QueryComponents::Suggest.new(search_params).payload
      }

      response = spelling_index.raw_search(query)

      response['suggest']
    end

  private

    attr_reader :metasearch_index

    def content_index_names
      # index is a IndexForSearch object, which combines all the content indexes
      index.index_names
    end
  end
end
