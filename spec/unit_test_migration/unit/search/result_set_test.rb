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
              "_type" => "contact",
              "_id" => "some_id",
              "_source" => { "foo" => "bar" },
            }
          ]
        }
      }
    end

    should "report one result" do
      assert_equal 1, Search::ResultSet.from_elasticsearch(sample_elasticsearch_types, @response).total
    end

    should "pass the fields to Document.from_hash" do
      expected_hash = has_entry("foo", "bar")
      Document.expects(:from_hash).with(expected_hash, sample_elasticsearch_types, anything).returns(:doc)

      result_set = Search::ResultSet.from_elasticsearch(sample_elasticsearch_types, @response)
      assert_equal [:doc], result_set.results
    end

    should "pass the result score to Document.from_hash" do
      Document.expects(:from_hash).with(is_a(Hash), sample_elasticsearch_types, 12).returns(:doc)

      result_set = Search::ResultSet.from_elasticsearch(sample_elasticsearch_types, @response)
      assert_equal [:doc], result_set.results
    end

    should "populate the document id and type from the metafields" do
      expected_hash = has_entries("_type" => "contact", "_id" => "some_id")
      Document.expects(:from_hash).with(expected_hash, sample_elasticsearch_types, anything).returns(:doc)

      result_set = Search::ResultSet.from_elasticsearch(sample_elasticsearch_types, @response)
      assert_equal [:doc], result_set.results
    end
  end
end
