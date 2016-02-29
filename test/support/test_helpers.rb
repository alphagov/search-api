module TestHelpers
  def teardown
    Timecop.return
  end

  def search_query_params(options = {})
    Search::SearchParameters.new({
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

  def stub_tagging_lookup
    stub_request(:get, %r[#{Plek.find('contentapi')}/*]).
      to_return(status: 404, body: {}.to_json)
  end
end
