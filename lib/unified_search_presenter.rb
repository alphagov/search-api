require "elasticsearch/result_set"
require "facet_option"
require "field_presenter"
require "result_set_presenter"

# Presents a combined set of results for a GOV.UK site search
class UnifiedSearchPresenter

  # `registries` should be a map from registry names to registries,
  # which gets passed to the ResultSetPresenter class. For example:
  #
  #     { organisation_registry: OrganisationRegistry.new(...) }
  #
  # `facet_examples` is {field_name => {facet_value => {total: count, examples: [{field: value}, ...]}}}
  # ie: a hash keyed by field name, containing hashes keyed by facet value with
  # values containing example information for the value.
  def initialize(es_response, start, index_names, applied_filters = {},
                 facet_fields = {}, registries = {},
                 registry_by_field = {}, suggestions = [],
                 facet_examples={})
    @start = start
    @results = es_response["hits"]["hits"].map do |result|
      doc = result.delete("fields")
      doc[:_metadata] = result
      doc
    end
    @facets = es_response["facets"]
    @total = es_response["hits"]["total"]
    @index_names = index_names
    @applied_filters = applied_filters
    @facet_fields = facet_fields
    @registries = registries
    @registry_by_field = registry_by_field
    @suggestions = suggestions
    @facet_examples = facet_examples
  end

  def present
    {
      results: presented_results,
      total: @total,
      start: @start,
      facets: presented_facets,
      suggested_queries: @suggestions
    }
  end

private

  attr_reader :registries, :registry_by_field

  def presented_results
    # This uses the "standard" ResultSetPresenter to expand fields like
    # organisations and topics.  It then makes a few further changes to tidy up
    # the output in other ways.

    result_set = ResultSet.new(@results, nil)
    ResultSetPresenter.new(result_set, registries).present["results"].each do |fields|
      metadata = fields.delete(:_metadata)

      # Replace the "_index" field, which contains the concrete name of the
      # index, with an "index" field containing the aliased name of the index
      # (eg, "mainstream").
      long_name = metadata["_index"]
      fields[:index] = @index_names.find { |short_name|
        long_name.start_with? short_name
      }

      # Put the elasticsearch score in es_score; this is used in templates when
      # debugging is requested, so it's nicer to be explicit about what score
      # it is.
      fields[:es_score] = metadata["_score"]
      fields[:_id] = metadata["_id"]

      explain = metadata["_explanation"]
      unless explain.nil?
        fields[:_explanation] = explain
      end

    end
  end

  def field_presenter
    @field_presenter ||= FieldPresenter.new(registry_by_field)
  end

  def facet_option_fields(field, slug)
    result = field_presenter.expand(field, slug)
    unless result.is_a?(Hash)
      result = {"slug" => result}
    end
    field_examples = @facet_examples[field]
    unless field_examples.nil?
      result["example_info"] = field_examples.fetch(slug, [])
    end
    result
  end

  def make_facet_option(field, term, count, applied, orderings)
    FacetOption.new(
      facet_option_fields(field, term),
      count,
      applied,
      orderings,
    )
  end

  # Get the facet options, sorted according to the "order" option.
  #
  # Returns the requested number of options, but will additionally return any
  # options which are part of a filter. 
  def facet_options(field, options, facet_parameters)
    requested_count = facet_parameters[:requested]
    orderings = facet_parameters[:order]
    applied_options = (@applied_filters[field] || []).dup

    all_options = options.map { |option|
      term, count = option["term"], option["count"]
      make_facet_option(field, term, count,
        !applied_options.delete(term).nil?,
        orderings,
      )
    }
    all_options.concat applied_options.map { |term|
      make_facet_option(field, term, 0, true, orderings)
    }
 
    results = []
    results_with_count = 0
    all_options.sort.each { |option|
      if results_with_count < requested_count || option.applied
        results << option.as_hash
        if option.count > 0
          results_with_count += 1
        end
      end
    }
    results
  end

  def presented_facets
    if @facets.nil?
      return {}
    end
    result = {}
    @facets.each do |field, facet_info|
      facet_parameters = @facet_fields[field]
      options = facet_info["terms"]
      result[field] = {
        options: facet_options(field, options, facet_parameters),
        documents_with_no_value: facet_info["missing"],
        total_options: options.length,
        missing_options: [options.length - facet_parameters[:requested], 0].max,
      }
    end
    result
  end
end
