# Performs a search across all indices used for the GOV.UK site search

require "facet_example_fetcher"
require "unified_search_builder"
require "unified_search_presenter"
require "unified_search/spell_check_fetcher"

class UnifiedSearcher
  attr_reader :index, :registries

  def initialize(index, registries)
    @index = index
    @registries = registries
  end

  # Search and combine the indices and return a hash of ResultSet objects
  def search(search_params)
    builder = UnifiedSearchBuilder.new(search_params)
    es_response = index.raw_search(builder.payload)

    example_fetcher = FacetExampleFetcher.new(index, es_response, search_params, builder)
    facet_examples = example_fetcher.fetch

    # Augment the response with the suggest result from a separate query.
    if search_params.suggest_spelling?
      es_response['suggest'] = fetch_spell_checks(search_params)
    end

    UnifiedSearchPresenter.new(
      search_params,
      es_response,
      registries,
      facet_examples,
      index.schema
    ).present
  end

private

  def fetch_spell_checks(search_params)
    UnifiedSearch::SpellCheckFetcher.new(search_params, registries).es_response
  end
end
