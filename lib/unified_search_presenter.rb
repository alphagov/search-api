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

  attr_reader :registries, :schema

  def suggested_queries
    UnifiedSearch::SpellCheckPresenter.new(es_response).present
  end

  # This uses the "standard" ResultPresenter to expand fields like
  # organisations and topics. It then makes a few further changes to tidy up
  # the output in other ways.
  def presented_results
    results = result_set.results.map do |document|
      ResultPresenter.new(document, registries, schema).present
    end

    results.map { |result| present_result_with_metadata(result) }
  end

  def result_set
    search_results = es_response["hits"]["hits"].map do |result|
      doc = result.delete("fields") || {}
      doc[:_metadata] = result
      doc
    end

    ResultSet.new(search_results, nil)
  end

  def presented_facets
    FacetResultPresenter.new(@facets, @facet_examples, @search_params, @registries).presented_facets
  end

  def present_result_with_metadata(result)
    metadata = result.delete(:_metadata)

    # Translate index names like `mainstream-2015-05-06t09..` into its
    # proper name, eg. "mainstream", "government" or "service-manual".
    # The regex takes the string until the first digit. After that, strip any
    # trailing dash from the string.
    result[:index] = metadata["_index"].match(%r[^\D+]).to_s.chomp('-')

    # Put the elasticsearch score in es_score; this is used in templates when
    # debugging is requested, so it's nicer to be explicit about what score
    # it is.
    result[:es_score] = metadata["_score"]
    result[:_id] = metadata["_id"]

    if metadata["_explanation"]
      result[:_explanation] = metadata["_explanation"]
    end

    result[:document_type] = metadata["_type"]
    result
  end
end
