require "result_set_presenter"

# Presents a combined set of results for a GOV.UK site search
class GovukSearchPresenter

  STREAM_TITLES = {
    "top-results" => "Top results",
    "services-information" => "Services and information",
    "departments-policy" => "Departments and policy"
  }

  # The `result_sets` hash should be a map from stream names to ResultSet
  # instances.
  #
  # `presenter_context` should be a map from registry names to registries,
  # which gets passed to the ResultSetPresenter class. For example:
  #
  #     { organisation_registry: OrganisationRegistry.new(...) }
  def initialize(result_sets, presenter_context = {})
    unknown_keys = result_sets.keys - STREAM_TITLES.keys
    if unknown_keys.any?
      raise ArgumentError, "Unrecognised streams: #{unknown_keys.join(', ')}"
    end

    @result_sets = result_sets
    @presenter_context = presenter_context
  end

  def present
    output = {"streams" => {}}
    presenters.each do |key, rs_presenter|
      presented_stream = rs_presenter.present
      output["streams"][key] = presented_stream.merge("title" => STREAM_TITLES[key])
    end

    output
  end

private

  def presenters
    Hash[@result_sets.map {|key, result_set|
      [key, ResultSetPresenter.new(result_set, @presenter_context)]
    }]
  end
end
