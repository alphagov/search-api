require "elasticsearch/result_set"
require "facet_option"
require "field_presenter"
require "result_set_presenter"
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
    @applied_filters = search_params[:filters] || []
    @facet_fields = search_params[:facets] || {}

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

  # This uses the "standard" ResultSetPresenter to expand fields like
  # organisations and topics. It then makes a few further changes to tidy up
  # the output in other ways.
  def presented_results
    presenter = ResultSetPresenter.new(result_set, registries, schema)
    results = presenter.present["results"]
    results.map { |result| present_result_with_metadata(result) }
  end

  def field_presenter
    @field_presenter ||= FieldPresenter.new(registries)
  end

  def result_set
    search_results = es_response["hits"]["hits"].map do |result|
      doc = result.delete("fields") || {}
      doc[:_metadata] = result
      doc
    end

    ResultSet.new(search_results, nil)
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
    filter = @applied_filters.find { |applied_filter| applied_filter.field_name == field }
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
