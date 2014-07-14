require "elasticsearch/result_set"
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

  def raw_facet_options(applied_options, options, requested_count)
    if applied_options.empty?
      applied = []
    else
      option_counts = Hash[options.map { |option|
        [option["term"], option["count"]]
      }]
      option_counts.default = 0
      applied = applied_options.map do |term|
        { "term" => term, "count" => option_counts[term] }
      end
    end

    top_unapplied = options.slice(0, requested_count).reject do |option|
      applied.include? option
    end

    applied + top_unapplied
  end

  def field_presenter
    @field_presenter ||= FieldPresenter.new(registry_by_field)
  end

  def facet_option(field, slug)
    result = field_presenter.expand(field, slug)
    field_examples = @facet_examples[field]
    unless field_examples.nil?
      unless result.is_a?(Hash)
        result = {"slug" => result}
      end
      result["example_info"] = field_examples.fetch(slug, [])
    end
    result
  end

  def facet_options(field, options, facet_parameters)
    requested_count = facet_parameters[:requested]
    applied_options = @applied_filters[field] || []
    raw_facet_options(applied_options, options, requested_count).map { |option|
      {
        value: facet_option(field, option["term"]),
        documents: option["count"],
      }
    }
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
