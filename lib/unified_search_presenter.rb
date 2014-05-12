require "elasticsearch/result_set"
require "field_presenter"
require "result_set_presenter"

# Presents a combined set of results for a GOV.UK site search
class UnifiedSearchPresenter

  # `registries` should be a map from registry names to registries,
  # which gets passed to the ResultSetPresenter class. For example:
  #
  #     { organisation_registry: OrganisationRegistry.new(...) }
  def initialize(es_response, start, index_names, applied_filters = {},
                 facet_fields = {}, registries = {},
                 registry_by_field = {}, suggestions = [])
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

    end
  end

  def presented_facets
    if @facets.nil?
      return {}
    end
    presenter = FieldPresenter.new(registry_by_field)
    result = {}
    @facets.each do |field, facet_info|
      requested_count = @facet_fields[field]
      options = facet_info["terms"]
      applied = @applied_filters[field] || []
      unless applied.empty?
        option_counts = Hash[facet_info["terms"].map { |option|
          [option["term"], option["count"]]
        }]
        option_counts.default = 0
        applied = (@applied_filters[field] || []).map do |term|
          { "term" => term, "count" => option_counts[term] }
        end
      end
      top_unapplied = options.slice(0, requested_count).reject do |option|
        applied.include? option
      end
      display_options = applied + top_unapplied
      result[field] = {
        options: display_options.map do |option|
          {
            value: presenter.expand(field, option["term"]),
            documents: option["count"],
          }
        end,
        documents_with_no_value: facet_info["missing"],
        total_options: options.length,
        missing_options: [options.length - requested_count, 0].max,
      }
    end
    result
  end
end
