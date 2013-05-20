class ResultSetPresenter

  def initialize(result_set)
    @result_set = result_set
  end

  def present
    MultiJson.encode(results)
  end

  def present_with_total
    MultiJson.encode(
      total: @result_set.total,
      results: results
    )
  end

private
  def results
    @result_set.results.map { |r| r.to_hash.merge(
      presentation_format: r.presentation_format,
      humanized_format: r.humanized_format
    )}
  end
end
