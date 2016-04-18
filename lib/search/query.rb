# Performs a search across all indices used for the GOV.UK site search

require_relative "facet_example_fetcher"
require_relative "query_builder"
require_relative "presenters/result_set_presenter"
require_relative "spell_check_fetcher"

module Search
  class Query
    attr_reader :index, :registries

    def initialize(index, registries)
      @index = index
      @registries = registries
    end

    # Search and combine the indices and return a hash of ResultSet objects
    def run(search_params)
      builder = QueryBuilder.new(search_params)
      es_response = index.raw_search(builder.payload)

      example_fetcher = FacetExampleFetcher.new(index, es_response, search_params, builder)
      facet_examples = example_fetcher.fetch

      # Augment the response with the suggest result from a separate query.
      if search_params.suggest_spelling?
        es_response['suggest'] = fetch_spell_checks(search_params)
      end

      ResultSetPresenter.new(
        search_params: search_params,
        es_response: es_response,
        registries: registries,
        facet_examples: facet_examples,
        schema: index.schema
      ).present
    end

  private

    def fetch_spell_checks(search_params)
      SpellCheckFetcher.new(search_params, registries).es_response
    end
  end
end
