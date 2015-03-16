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
                 facet_examples={}, schema=nil)
    @start = start
    @results = es_response["hits"]["hits"].map do |result|
      doc = result.delete("fields") || {}
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
    @schema = schema
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

  attr_reader :registries, :registry_by_field, :schema

  def presented_results
    # This uses the "standard" ResultSetPresenter to expand fields like
    # organisations and topics.  It then makes a few further changes to tidy up
    # the output in other ways.

    result_set = ResultSet.new(@results, nil)
    ResultSetPresenter.new(result_set, registries, schema).present["results"].each do |fields|
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

      fields[:document_type] = metadata["_type"]
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

  # Pick the top facet options, but include all applied facet options.
  #
  # Also, when picking the top facet options, don't count facet options which
  # have a count of 0 documents (these happen when a filter is applied, but the
  # filter doesn't match any documents for the current query).  This means that
  # if a load of filters are applied, and the query is then changed while
  # keeping the filters such that the filters match no documents, then the old
  # filters are still returned in the response (so get shown in the UI such
  # that the user can remove them), but a new set of filters are also suggested
  # which might actually be useful.
  def top_facet_options(options, requested_count)
    suggested_options = options.sort.select { |option|
      option.count > 0
    }.take(requested_count)
    applied_options = options.select(&:applied)
    suggested_options.concat(applied_options).uniq.sort.map(&:as_hash)
  end

  # Get the facet options, sorted according to the "order" option.
  #
  # Returns the requested number of options, but will additionally return any
  # options which are part of a filter. 
  def facet_options(field, calculated_options, facet_parameters)
    applied_options = filter_values_for_field(field)

    all_options = calculated_options.map { |option|
      [option["term"], option["count"]]
    } + applied_options.map { |term|
      [term, 0]
    }

    unique_options = all_options.uniq { |term, count|
      term
    }

    option_objects = unique_options.map { |term, count|
      make_facet_option(field, term, count,
        applied_options.include?(term),
        facet_parameters[:order],
      )
    }

    top_facet_options(option_objects, facet_parameters[:requested])
  end

  def filter_values_for_field(field)
    filter = @applied_filters.find { |filter| filter.field_name == field }

    filter ? filter.values : []
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
        scope: facet_parameters[:scope],
      }
    end
    result
  end
end
