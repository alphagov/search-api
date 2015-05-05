require_relative "../../test_helper"
require "health_check/logging_config"
require "health_check/local_search_client"
Logging.logger.root.appenders = nil

module HealthCheck
  class LocalSearchClientTest < ShouldaUnitTestCase
    def setup
      @search_index = stub("search index")
      @index_name = "my index"
      @search_server = stub("search server")
      @search_server.stubs(:index).with(@index_name).returns(@search_index)
      SearchConfig.any_instance.stubs(:search_server).returns(@search_server)
    end

    should "get the index from the SearchConfig by name" do
      @search_server.expects(:index).with(@index_name)
      LocalSearchClient.new(index: @index_name)
    end

    should "perform a search using the index and extract results" do
      term = "food"
      result = stub("result", link: "/food")
      result_set = stub("result set", results: [result])
      @search_index.expects(:search).with(term).returns(result_set)

      client = LocalSearchClient.new(index: @index_name)
      expected = { results: [result.link] }
      assert_equal expected, client.search(term)
    end
  end
end
