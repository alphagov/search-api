require "facet_option"
require "field_presenter"

class FacetResultPresenter
  attr_reader :facets, :facet_examples, :search_params, :registries

  def initialize(facets, facet_examples, search_params, registries)
    @facets = facets
    @facet_examples = facet_examples
    @search_params = search_params
    @registries = registries
  end

  def presented_facets
    return {} if facets.nil?

    result = {}
    facets.each do |field, facet_info|
      facet_parameters = facet_fields[field]

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

private

  def applied_filters
    search_params[:filters] || []
  end

  def facet_fields
    search_params[:facets] || {}
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
    filter = applied_filters.find { |applied_filter| applied_filter.field_name == field }
    filter ? filter.values : []
  end

  def make_facet_option(field, term, count, applied, orderings)
    FacetOption.new(
      facet_option_fields(field, term),
      count,
      applied,
      orderings,
    )
  end

  def facet_option_fields(field, slug)
    result = field_presenter.expand(field, slug)
    unless result.is_a?(Hash)
      result = {"slug" => result}
    end

    field_examples = facet_examples[field]

    unless field_examples.nil?
      result["example_info"] = field_examples.fetch(slug, [])
    end
    result
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

  def field_presenter
    @field_presenter ||= FieldPresenter.new(registries)
  end
end
