require "elasticsearch/result_set"
require "field_presenter"
require "result_set_presenter"

# Presents a combined set of results for a GOV.UK site search
class UnifiedSearchPresenter

  attr_reader :results, :registries, :registry_by_field

  # `registries` should be a map from registry names to registries,
  # which gets passed to the ResultSetPresenter class. For example:
  #
  #     { organisation_registry: OrganisationRegistry.new(...) }
  def initialize(results, index_names, facet_fields = {}, registries = {},
                 registry_by_field = {})
    @results = results
    @index_names = index_names
    @facet_fields = facet_fields
    @registries = registries
    @registry_by_field = registry_by_field
  end

  def present
    {
      results: presented_results,
      total: results[:total],
      start: results[:start],
      facets: presented_facets,
    }
  end

private

  def presented_results
    # This uses the "standard" ResultSetPresenter to expand fields like
    # organisations and topics.  It then makes a few further changes to tidy up
    # the output in other ways.

    result_set = ResultSet.new(results[:results], nil)
    ResultSetPresenter.new(result_set, registries).present["results"].each do |fields|
      metadata = fields.delete(:_metadata)

      # Replace the "_index" field, which contains the concrete name of the
      # index, with an "index" field containing the aliased name of the index
      # (eg, "mainstream").
      long_name = metadata["_index"]
      @index_names.each do |short_name|
        if long_name.start_with? short_name
          fields[:index] = short_name
        end
      end

      # Put the elasticsearch score in es_score; this is used in templates when
      # debugging is requested, so it's nicer to be explicit about what score
      # it is.
      fields[:es_score] = metadata["_score"]
      fields[:_id] = metadata["_id"]

    end
  end

  def presented_facets
    if results[:facets] == nil
      return {}
    end
    presenter = FieldPresenter.new(registry_by_field)
    result = {}
    results[:facets].each do |field, facet_info|
      requested_count = @facet_fields[field]
      options = facet_info["terms"]
      display_options = options.slice(0, requested_count)
      result[field] = {
        options: display_options.map do |option|
          {
            value: presenter.expand(field, option["term"]),
            documents: option["count"],
          }
        end,
        documents_with_no_value: facet_info["missing"],
        total_options: options.length,
        missing_options: options.length - display_options.length,
      }
    end
    result
  end
end
