require "result_set_presenter"

# Presents a combined set of results for a GOV.UK site search
class UnifiedSearchPresenter

  attr_reader :results, :registries

  # `presenter_context` should be a map from registry names to registries,
  # which gets passed to the ResultSetPresenter class. For example:
  #
  #     { organisation_registry: OrganisationRegistry.new(...) }
  def initialize(results, registries = {}, index_names)
    @results = results
    @registries = registries
    @index_names = index_names
  end

  def present
    {
      results: presented_results,
      total: results[:total],
      start: results[:start],
    }
  end

private

  def presented_results
    # This uses the "standard" ResultSetPresenter to expand fields like
    # organisations and topics.  It then makes a few further changes to tidy up
    # the output in other ways.

    result_set = ResultSet.new(results[:results], nil)
    ResultSetPresenter.new(result_set, registries).present["results"].each do |fields|

      # Replace the "_index" field, which contains the concrete name of the
      # index, with an "index" field containing the aliased name of the index
      # (eg, "mainstream").
      long_name = fields.delete("_index")
      @index_names.each do |short_name|
        if long_name.start_with? short_name
          fields[:index] = short_name
        end
      end

      # Put the elasticsearch score in es_score; this is used in templates when
      # debugging is requested, so it's nicer to be explicit about what score
      # it is.
      fields[:es_score] = fields.delete("_score")

    end
  end
end
