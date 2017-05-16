# Performs a search across all indices used for the GOV.UK site search

require_relative "aggregate_example_fetcher"
require_relative "query_builder"
require_relative "presenters/result_set_presenter"
require_relative "spell_check_fetcher"

module Search
  class Query
    attr_reader :index, :registries

    def initialize(index, registries, metasearch_index:)
      @index = index
      @registries = registries
      @metasearch_index = metasearch_index
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
        es_response['suggest'] = fetch_spell_checks(search_params)
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

  private

    attr_reader :metasearch_index

    def content_index_names
      # index is a IndexForSearch object, which combines all the content indexes
      index.index_names
    end

    def fetch_spell_checks(search_params)
      SpellCheckFetcher.new(search_params, registries).es_response
    end
  end
end
