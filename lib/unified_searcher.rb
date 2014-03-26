# Performs a search across all indices used for the GOV.UK site search

require "unified_search_builder"

class UnifiedSearcher

  attr_reader :index

  def initialize(index)
    @index = index
  end

  # Search and combine the indices and return a hash of ResultSet objects
  def search(start, count, query, order, filters)
    start = start || 0
    count = count || 10
    builder = UnifiedSearchBuilder.new(start, count, query, order, filters, nil)

    results = index.raw_search(builder.payload)
    {
      start: start,
      results: results["hits"]["hits"].map do |result|
        doc = result.delete("fields")
        doc = doc.merge(result)
        doc["_index"] = doc["_index"]
        doc
      end,
      total: results["hits"]["total"],
    }
  end
end
