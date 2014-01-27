require "test_helper"
require "document"
require "elasticsearch/result_set"

class ResultSetTest < ShouldaUnitTestCase

  FIELDS = %w(link title description format)

  def mappings
    {
      "edition" => {
        "properties" => Hash[FIELDS.map { |f| [f, { "type" => "foo" }] }]
      }
    }
  end

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
      assert_equal 0, ResultSet.from_elasticsearch(mappings, @response).total
    end

    should "have an empty result set" do
      result_set = ResultSet.from_elasticsearch(mappings, @response)
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
              "_source" => { "foo" => "bar" }
            }
          ]
        }
      }
    end

    should "report one result" do
      assert_equal 1, ResultSet.from_elasticsearch(mappings, @response).total
    end

    should "pass the fields to Document.from_hash" do
      expected_hash = has_entry("foo", "bar")
      Document.expects(:from_hash).with(expected_hash, mappings, anything).returns(:doc)

      result_set = ResultSet.from_elasticsearch(mappings, @response)
      assert_equal [:doc], result_set.results
    end

    should "pass the result score to Document.from_hash" do
      Document.expects(:from_hash).with(is_a(Hash), mappings, 12).returns(:doc)

      result_set = ResultSet.from_elasticsearch(mappings, @response)
      assert_equal [:doc], result_set.results
    end
  end

  context "weighted results" do
    setup do
      weighted_1 = stub(es_score: 0.6)
      document_1 = mock("Document 1") do
        expects(:weighted).with(0.5).returns(weighted_1)
      end
      weighted_2 = stub(es_score: 0.4)
      document_2 = mock("Document 2") do
        expects(:weighted).with(0.5).returns(weighted_2)
      end
      @result_set = ResultSet.new([document_1, document_2], 12)
    end

    should "weight each result" do
      weighted_result_set = @result_set.weighted(0.5)
      assert_equal [0.6, 0.4], weighted_result_set.results.map(&:es_score)
    end

    should "keep the same total" do
      weighted_result_set = @result_set.weighted(0.5)
      assert_equal 12, weighted_result_set.total
    end
  end
end
