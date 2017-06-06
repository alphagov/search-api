require "test_helper"
require "search/query"

class QueryTest < ShouldaUnitTestCase
  context "#search" do
    should 'search with the results from the builder and return a presenter' do
      index = stub('index', :schema)

      search_payload = stub('payload')
      Search::QueryBuilder.any_instance.expects(:payload).returns(search_payload)
      index.expects(:raw_search).with(search_payload, search_type: "query_then_fetch").returns({})

      Search::FacetExampleFetcher.any_instance.expects(:fetch).returns(stub('fetch'))
      Search::ResultSetPresenter.any_instance.expects(:present).returns(stub('presenter'))

      Search::Query.new(index, stub).run(Search::QueryParameters.new({}))
    end
  end
end
