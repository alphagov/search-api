require "test_helper"
require "unified_searcher"

class UnifiedSearcherTest < ShouldaUnitTestCase
  context "#search" do
    should 'search with the results from the builder and return a presenter' do
      index = stub('index', :schema)

      search_payload = stub('payload')
      UnifiedSearchBuilder.any_instance.expects(:payload).returns(search_payload)
      index.expects(:raw_search).with(search_payload).returns({})

      FacetExampleFetcher.any_instance.expects(:fetch).returns(stub('fetch'))
      UnifiedSearchPresenter.any_instance.expects(:present).returns(stub('presenter'))

      UnifiedSearcher.new(index, stub).search(SearchParameters.new({}))
    end
  end
end
