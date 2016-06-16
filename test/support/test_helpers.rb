require "gds_api/test_helpers/publishing_api_v2"

module TestHelpers
  include GdsApi::TestHelpers::PublishingApiV2

  def teardown
    Timecop.return
  end

  def search_query_params(options = {})
    Search::QueryParameters.new({
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

  # This works because we first try to look up the content id for the base path.
  def stub_tagging_lookup
    publishing_api_has_lookups({})
  end
end
