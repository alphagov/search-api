require "elasticsearch/result_set"
require "result_presenter"
require "facet_result_presenter"
require "unified_search/spell_check_presenter"

# Presents a combined set of results for a GOV.UK site search
class UnifiedSearchPresenter
  attr_reader :es_response, :search_params

  # `registries` should be a map from registry names to registries,
  # which gets passed to the ResultSetPresenter class. For example:
  #
  #     { organisations: OrganisationRegistry.new(...) }
  #
  # `facet_examples` is {field_name => {facet_value => {total: count, examples: [{field: value}, ...]}}}
  # ie: a hash keyed by field name, containing hashes keyed by facet value with
  # values containing example information for the value.
  def initialize(search_params,
                 es_response,
                 registries = {},
                 facet_examples = {},
                 schema = nil)

    @es_response = es_response
    @facets = es_response["facets"]
    @search_params = search_params
    @registries = registries
    @facet_examples = facet_examples
    @schema = schema
  end

  def present
    {
      results: presented_results,
      total: es_response["hits"]["total"],
      start: search_params[:start],
      facets: presented_facets,
      suggested_queries: suggested_queries
    }
  end

private

  def suggested_queries
    UnifiedSearch::SpellCheckPresenter.new(es_response).present
  end

  def presented_results
    results = es_response["hits"]["hits"].map do |result|
      doc = result.delete("fields") || {}
      doc[:_raw_result] = result.freeze
      doc
    end

    results = results.map do |document|
      ResultPresenter.new(document, @registries, @schema).present
    end

    results.map do |result|
      result.delete(:_raw_result)
      result
    end
  end

  def presented_facets
    FacetResultPresenter.new(@facets, @facet_examples, @search_params, @registries).presented_facets
  end
end
