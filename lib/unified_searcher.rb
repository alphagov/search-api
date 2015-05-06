# Performs a search across all indices used for the GOV.UK site search

require "facet_example_fetcher"
require "unified_search_builder"
require "unified_search_presenter"

class UnifiedSearcher

  attr_reader :index, :registries, :suggester

  def initialize(index, metaindex, registries, suggester)
    @index = index
    @metaindex = metaindex
    @registries = registries
    @suggester = suggester
  end

  # Search and combine the indices and return a hash of ResultSet objects
  def search(params)
    builder = UnifiedSearchBuilder.new(params, @metaindex)
    es_response = index.raw_search(builder.payload)
    example_fetcher = FacetExampleFetcher.new(index, es_response, params,
                                              builder)
    facet_examples = example_fetcher.fetch
    UnifiedSearchPresenter.new(
      params,
      es_response,
      registries,
      suggested_queries(params[:query]),
      facet_examples,
      index.schema
    ).present
  end

private

  def suggested_queries(query)
    query.nil? ? [] : @suggester.suggestions(query)
  end
end
