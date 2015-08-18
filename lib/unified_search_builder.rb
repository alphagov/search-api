require "best_bets_checker"
require "elasticsearch/escaping"

require "query_components/base_component"
require "query_components/booster"
require "query_components/sort"
require "query_components/popularity"
require "query_components/best_bets"
require "query_components/query"
require "query_components/filter"
require "query_components/highlight"
require "query_components/facets"

# Builds a query for a search across all GOV.UK indices
class UnifiedSearchBuilder
  attr_reader :search_params

  def initialize(search_params)
    @search_params = search_params
  end

  def payload
    hash_without_blank_values(
      from: search_params.start,
      size: search_params.count,
      # `title` and `description` always needed to potentially populate virtual
      # fields. If not explicitly requested they will not be sent to the user.
      fields: search_params.return_fields + %w[title description],
      query: query,
      filter: filter,
      sort: sort,
      facets: facets,
      highlight: highlight,
      explain: search_params.debug[:explain],
    )
  end

  def query
    QueryComponents::Query.new(search_params).payload
  end

  def filter
    QueryComponents::Filter.new(search_params).payload
  end

  private

  def sort
    QueryComponents::Sort.new(search_params).payload
  end

  def facets
    QueryComponents::Facets.new(search_params).payload
  end

  def highlight
    QueryComponents::Highlight.new(search_params).payload
  end

  def hash_without_blank_values(hash)
    Hash[hash.reject { |key, value|
      [nil, [], {}].include?(value)
    }]
  end
end
