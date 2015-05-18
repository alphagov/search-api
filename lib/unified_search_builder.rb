require "best_bets_checker"
require "elasticsearch/escaping"

require "query_components/base_component"
require "query_components/booster"
require "query_components/core_query"
require "query_components/sort"
require "query_components/popularity"
require "query_components/best_bets"
require "query_components/query"
require "query_components/filter"
require "query_components/facets"

# Builds a query for a search across all GOV.UK indices
class UnifiedSearchBuilder
  attr_reader :params

  def initialize(params)
    @params = params
  end

  def payload
    hash_without_blank_values(
      from: params[:start],
      size: params[:count],
      fields: params[:return_fields],
      query: query,
      filter: filter,
      sort: sort,
      facets: facets,
      explain: explain_query?,
    )
  end

  def query
    QueryComponents::Query.new(params).payload
  end

  def filter
    QueryComponents::Filter.new(params).payload
  end

  private

  def sort
    QueryComponents::Sort.new(params).payload
  end

  def facets
    QueryComponents::Facets.new(params).payload
  end

  def explain_query?
    params[:debug] && params[:debug][:explain]
  end

  def hash_without_blank_values(hash)
    Hash[hash.reject { |key, value|
      [nil, [], {}].include?(value)
    }]
  end
end
