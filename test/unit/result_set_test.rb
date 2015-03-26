require "test_helper"
require "document"
require "elasticsearch/result_set"

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
      assert_equal 0, ResultSet.from_elasticsearch(sample_document_types, @response).total
    end

    should "have an empty result set" do
      result_set = ResultSet.from_elasticsearch(sample_document_types, @response)
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
      assert_equal 1, ResultSet.from_elasticsearch(sample_document_types, @response).total
    end

    should "pass the fields to Document.from_hash" do
      expected_hash = has_entry("foo", "bar")
      Document.expects(:from_hash).with(expected_hash, sample_document_types, anything).returns(:doc)

      result_set = ResultSet.from_elasticsearch(sample_document_types, @response)
      assert_equal [:doc], result_set.results
    end

    should "pass the result score to Document.from_hash" do
      Document.expects(:from_hash).with(is_a(Hash), sample_document_types, 12).returns(:doc)

      result_set = ResultSet.from_elasticsearch(sample_document_types, @response)
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

  context "merged result sets" do
    setup do
      docs_1 = [
        stub(link: "/a", es_score: 4),
        stub(link: "/b", es_score: 2)
      ]
      @result_set = ResultSet.new(docs_1)

      docs_2 = [
        stub(link: "/c", es_score: 3),
        stub(link: "/d", es_score: 1)
      ]
      @other = ResultSet.new(docs_2, 5)
    end

    should "merge and sort the results" do
      merged = @result_set.merge(@other)
      assert_equal %w(/a /c /b /d), merged.results.map(&:link)
    end

    should "sum the totals" do
      merged = @result_set.merge(@other)
      assert_equal 7, merged.total
    end
  end

  context "taking results" do
    setup do
      results = [:foo, :bar, :baz]
      @result_set = ResultSet.new(results, 10)
    end

    should "take the first n results" do
      top_results = @result_set.take(2)
      assert_equal [:foo, :bar], top_results.results
    end

    should "leave the total count unchanged" do
      top_results = @result_set.take(2)
      assert_equal 10, top_results.total
    end

    should "take up to n results" do
      top_results = @result_set.take(5)
      assert_equal [:foo, :bar, :baz], top_results.results
    end
  end

  context "subtracting result sets" do
    setup do
      @documents = %w(/1 /2 /3 /4 /5).map { |link|
        stub("Document #{link}", link: link)
      }
      @result_set = ResultSet.new(@documents[0,2], 10)
    end

    context "removing empty set" do
      setup do
        @other_result_set = ResultSet.new([], 2)
        @remainder = @result_set - @other_result_set
      end

      should "keep the same results" do
        assert_equal %w(/1 /2), @remainder.results.map(&:link)
      end

      should "keep the same total" do
        assert_equal 10, @remainder.total
      end
    end

    context "removing non-overlapping set" do
      setup do
        @other_result_set = ResultSet.new(@documents[3,2], 2)
        @remainder = @result_set - @other_result_set
      end

      should "keep the same results" do
        assert_equal %w(/1 /2), @remainder.results.map(&:link)
      end

      should "keep the same total" do
        assert_equal 10, @remainder.total
      end
    end

    context "removing overlapping set" do
      setup do
        @other_result_set = ResultSet.new(@documents[1,2], 2)
        @remainder = @result_set - @other_result_set
      end

      should "remove the shared results" do
        assert_equal %w(/1), @remainder.results.map(&:link)
      end

      should "subtract the shared count from the total" do
        assert_equal 9, @remainder.total
      end
    end
  end
end
