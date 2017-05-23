require "test_helper"
require "document"
require "search/result_set"

class ResultSetTest < ShouldaUnitTestCase
  context "empty result set" do
    setup do
      @response = {
        "hits" => {
          "total" => 0,
          "hits" => []
        }
      }
    end

    should "report zero results" do
      assert_equal 0, Search::ResultSet.from_elasticsearch(sample_elasticsearch_types, @response).total
    end

    should "have an empty result set" do
      result_set = Search::ResultSet.from_elasticsearch(sample_elasticsearch_types, @response)
      assert_equal 0, result_set.results.size
    end
  end

  context "single result" do
    setup do
      @response = {
        "hits" => {
          "total" => 1,
          "hits" => [
            {
              "_score" => 12,
              "_id" => "/foo",
              "_type" => "edition",
              "_source" => { "title" => "hello" }
            }
          ]
        }
      }
    end

    should "report one result" do
      assert_equal 1, Search::ResultSet.from_elasticsearch(sample_elasticsearch_types, @response).total
    end

    should "return attributes from source fields and the score" do
      result_set = Search::ResultSet.from_elasticsearch(sample_elasticsearch_types, @response)

      document = result_set.results.first
      assert_equal document.to_hash, {"title" => "hello", "es_score" => 12}
    end
  end
end
