# Performs a search across all indices used for the GOV.UK site search

require "unified_search_builder"
require "unified_search_presenter"

class UnifiedSearcher

  attr_reader :index, :registries, :registry_by_field, :suggester

  def initialize(index, registries, registry_by_field, suggester)
    @index = index
    @registries = registries
    @registry_by_field = registry_by_field
    @suggester = suggester
  end

  # Search and combine the indices and return a hash of ResultSet objects
  def search(params)
    builder = UnifiedSearchBuilder.new(params)
    es_response = index.raw_search(builder.payload)
    UnifiedSearchPresenter.new(
      es_response,
      params[:start],
      @index.index_name.split(","),
      params[:facets],
      registries,
      registry_by_field,
    ).present
  end

  private

  def suggested_queries(query)
    query.nil? ? [] : @suggester.suggestions(query)
  end
end
