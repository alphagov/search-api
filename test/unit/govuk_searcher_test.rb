require "test_helper"
require "set"
require "govuk_searcher"

class GovukSearcherTest < ShouldaUnitTestCase

  # results is a set of [score, link] pairs
  class FakeResultSet < Struct.new(:results)
    def merge(other)
      merged_results = (results + other.results).sort.reverse
      FakeResultSet.new(merged_results)
    end

    def weighted(factor)
      weighted_results = results.map { |score, link| [score * factor, link] }
      FakeResultSet.new(weighted_results)
    end

    def -(other)
      new_results = results.reject { |r| other.links.include?(r[1]) }
      FakeResultSet.new(new_results)
    end

    def take(count)
      FakeResultSet.new(results.take(count))
    end

    def links
      results.map { |r| r[1] }
    end
  end

  context "unfiltered, unsorted search" do

    setup do
      @mainstream = stub("mainstream index")
      @detailed = stub("detailed index")
      @government = stub("government index")
      @searcher = GovukSearcher.new(@mainstream, @detailed, @government)

      no_parameters = { organisation: nil, sort: nil }
      # No weighting
      @mainstream.expects(:search).with("cheese").returns(
        FakeResultSet.new([[6, "/m1"], [5, "/m2"], [3, "/m3"]])
      )
      # Weighted: 5.6, 3.2
      @detailed.expects(:search).with("cheese").returns(
        FakeResultSet.new([[7, "/d1"], [4, "/d2"]])
      )
      # Weighted: 4.8, 3.6
      @government.expects(:search).with("cheese", no_parameters).returns(
        FakeResultSet.new([[8, "/g1"], [6, "/g2"]])
      )

      @results = @searcher.search("cheese")
    end

    should "include the three result streams" do
      assert_equal(
        ["top-results", "services-information", "departments-policy"].to_set,
        @results.keys.to_set
      )
    end

    should "pull out the top three results" do
      assert_equal(["/m1", "/d1", "/m2"], @results["top-results"].links)
    end

    should "display the remaining results in their respective streams" do
      top_links = @results["top-results"].links

      assert_equal ["/d2", "/m3"], @results["services-information"].links
      assert_equal ["/g1", "/g2"], @results["departments-policy"].links
    end
  end

  context "filtered search" do

    setup do
      @mainstream = stub("mainstream index")
      @detailed = stub("detailed index")
      @government = stub("government index")
      @searcher = GovukSearcher.new(@mainstream, @detailed, @government)

      no_parameters = { organisation: nil, sort: nil }
      @mainstream.expects(:search).with("cheese").returns(
        FakeResultSet.new([[6, "/m1"]])
      )
      # Weighted: 4
      @detailed.expects(:search).with("cheese").returns(
        FakeResultSet.new([[5, "/d1"]])
      )
      # Weighted: 4.8, 3.6
      @government.expects(:search).with("cheese").returns(
        FakeResultSet.new([[8, "/g1"], [6, "/g2"]])
      )
      @government.expects(:search)
                 .with("cheese", organisation: "org", sort: nil)
                 .returns(FakeResultSet.new([[6, "/g1"]]))

      @results = @searcher.search("cheese", "org")
    end

    should "pull out the top three results, including unfiltered" do
      assert_equal(["/m1", "/g1", "/d1"], @results["top-results"].links)
    end

    should "display the remaining results in their respective streams" do
      top_links = @results["top-results"].links

      assert_equal [], @results["services-information"].links
      # /g1 was in the top results; /g2 is not in the unfiltered results
      assert_equal [], @results["departments-policy"].links
    end
  end

  context "sorted search" do

    setup do
      @mainstream = stub("mainstream index")
      @detailed = stub("detailed index")
      @government = stub("government index")
      @searcher = GovukSearcher.new(@mainstream, @detailed, @government)

      no_parameters = { organisation: nil, sort: nil }
      @mainstream.expects(:search).with("cheese").returns(
        FakeResultSet.new([[6, "/m1"]])
      )
      # Weighted: 4
      @detailed.expects(:search).with("cheese").returns(
        FakeResultSet.new([[5, "/d1"]])
      )
      # Weighted: 4.8, 3.6
      @government.expects(:search).with("cheese").returns(
        FakeResultSet.new([[8, "/g1"], [6, "/g2"]])
      )
      @government.expects(:search)
                 .with("cheese", organisation: nil, sort: "public_timestamp")
                 .returns(FakeResultSet.new([[6, "/g2"], [8, "/g1"]]))

      @results = @searcher.search("cheese", nil, "public_timestamp")
    end

    should "pull out the top three results" do
      assert_equal(["/m1", "/g1", "/d1"], @results["top-results"].links)
    end

    should "display the remaining results in their respective streams" do
      top_links = @results["top-results"].links

      assert_equal [], @results["services-information"].links
      # /g1 was in the top results; /g2 is not in the unfiltered results
      assert_equal ["/g2"], @results["departments-policy"].links
    end
  end
end
