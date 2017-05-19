require_relative "best_bets_checker"
require_relative "escaping"

require_relative "query_components/base_component"
require_relative "query_components/booster"
require_relative "query_components/sort"
require_relative "query_components/popularity"
require_relative "query_components/best_bets"
require_relative "query_components/query"
require_relative "query_components/filter"
require_relative "query_components/highlight"
require_relative "query_components/facets"

module Search
  # Builds a query for a search across all GOV.UK indices
  class QueryBuilder
    attr_reader :search_params

    def initialize(search_params)
      @search_params = search_params
    end

    def payload
      hash_without_blank_values({
        from: search_params.start,
        size: search_params.count,
        query: query,
        filter: filter,
        sort: sort,
        facets: facets,
        highlight: highlight,
        explain: search_params.debug[:explain],
      }
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
      Hash[hash.reject { |_key, value|
        [nil, [], {}].include?(value)
      }]
    end
  end
end
