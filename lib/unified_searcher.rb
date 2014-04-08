# Performs a search across all indices used for the GOV.UK site search

require "unified_search_builder"
require "unified_search_presenter"

class UnifiedSearcher

  attr_reader :index, :registries, :registry_by_field

  def initialize(index, registries, registry_by_field)
    @index = index
    @registries = registries
    @registry_by_field = registry_by_field
  end

  # Search and combine the indices and return a hash of ResultSet objects
  def search(start, count, query, order, filters, facet_fields)
    start = start || 0
    count = count || 10
    builder = UnifiedSearchBuilder.new(start, count, query, order, filters, nil, facet_fields)

    results = index.raw_search(builder.payload)
    results = {
      start: start,
      results: results["hits"]["hits"].map do |result|
        doc = result.delete("fields")
        doc[:_metadata] = result
        doc
      end,
      total: results["hits"]["total"],
      facets: results["facets"],
    }
    UnifiedSearchPresenter.new(
      results,
      @index.index_name.split(","),
      facet_fields,
      registries,
      registry_by_field,
    ).present
  end
end
