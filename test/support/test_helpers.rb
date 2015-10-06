module TestHelpers
  def teardown
    Timecop.return
  end

  def search_query_params(options={})
    SearchParameters.new({
      start: 0,
      count: 20,
      query: "cheese",
      order: nil,
      filters: {},
      return_fields: nil,
      facets: nil,
      debug: {},
    }.merge(options))
  end
end
