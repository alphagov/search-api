# Performs a search across all indices used for the GOV.UK site search

require "search/facet_example_fetcher"
require "search/search_builder"
require "search/presenters/search_presenter"
require "search/spell_check_fetcher"

class Searcher
  attr_reader :index, :registries

  def initialize(index, registries)
    @index = index
    @registries = registries
  end

  # Search and combine the indices and return a hash of ResultSet objects
  def search(search_params)
    builder = Search::SearchBuilder.new(search_params)
    es_response = index.raw_search(builder.payload)

    example_fetcher = Search::FacetExampleFetcher.new(index, es_response, search_params, builder)
    facet_examples = example_fetcher.fetch

    # Augment the response with the suggest result from a separate query.
    if search_params.suggest_spelling?
      es_response['suggest'] = fetch_spell_checks(search_params)
    end

    Search::SearchPresenter.new(
      search_params,
      es_response,
      registries,
      facet_examples,
      index.schema
    ).present
  end

private

  def fetch_spell_checks(search_params)
    Search::SpellCheckFetcher.new(search_params, registries).es_response
  end
end
