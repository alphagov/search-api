class ResultSetPresenter

  def initialize(results)
    @results = results
  end

  def present
    MultiJson.encode(@results.map { |r| r.to_hash.merge(
      presentation_format: r.presentation_format,
      humanized_format: r.humanized_format
    )})
  end
end
