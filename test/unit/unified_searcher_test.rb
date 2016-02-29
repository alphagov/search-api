require "test_helper"
require "searcher"

class SearcherTest < ShouldaUnitTestCase
  context "#search" do
    should 'search with the results from the builder and return a presenter' do
      index = stub('index', :schema)

      search_payload = stub('payload')
      Search::SearchBuilder.any_instance.expects(:payload).returns(search_payload)
      index.expects(:raw_search).with(search_payload).returns({})

      Search::FacetExampleFetcher.any_instance.expects(:fetch).returns(stub('fetch'))
      Search::SearchPresenter.any_instance.expects(:present).returns(stub('presenter'))

      Searcher.new(index, stub).search(Search::SearchParameters.new({}))
    end
  end
end
