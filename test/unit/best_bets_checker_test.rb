require "test_helper"
require "json"
require "best_bets_checker"

class BestBetsCheckerTest < ShouldaUnitTestCase

  def best_bets_query(query)
    {
      query: {
        bool: {
          should: [
            { match: { exact_query: query }},
            { match: { stemmed_query: query }}
          ]
        }
      },
      size: 1000,
      fields: [ :details, :stemmed_query_as_term ],
    }
  end

  def bb_hits(hits)
    { "hits" => {"hits" => hits, "total" => hits.length } }
  end

  def bb_doc(query, type, best_bets, worst_bets)
    {
      "_index" => "metasearch-2014-05-14t17:27:17z-bc245536-f1c1-4f95-83e4-596199b81f0a",
      "_type" => "best_bet",
      "_id" => "#{query}-#{type}",
      "_score" => 1.0,
      "fields" => {
        "details" => JSON.generate({
          best_bets: best_bets.map do |link, position|
            {link: link, position: position}
          end,
          worst_bets: worst_bets.map do |link|
            {link: link}
          end,
        })
      }
    }
  end

  def setup_checker(query, hits)
    @index = stub("metasearch index")
    @checker = BestBetsChecker.new(@index, query)
    @index.expects(:raw_search).with(
      best_bets_query(query), "best_bet"
    ).returns(
      bb_hits(hits)
    )
    @index.expects(:analyzed_best_bet_query).with(query).returns(query)
  end

  context "without best bets" do
    setup do
      setup_checker("foo", [])
    end

    should "not find any best bets" do
      assert_equal({}, @checker.best_bets)
    end

    should "not find any worst bets" do
      assert_equal([], @checker.worst_bets)
    end
  end

  context "with an exact best bet" do
    setup do
      setup_checker("foo", [
        bb_doc("foo", "exact", [["/jobsearch", 1]], [])
      ])
    end

    should "find one best bet" do
      assert_equal({1 => ["/jobsearch"]}, @checker.best_bets)
    end

    should "not find any worst bets" do
      assert_equal([], @checker.worst_bets)
    end
  end

  context "with an exact worst bet" do
    setup do
      setup_checker("foo", [
        bb_doc("foo", "exact", [], ["/jobsearch"])
      ])
    end

    should "not find any best bets" do
      assert_equal({}, @checker.best_bets)
    end

    should "find one worst bet" do
      assert_equal(["/jobsearch"], @checker.worst_bets)
    end
  end

  context "with an exact and a stemmed best bet" do
    setup do
      setup_checker("foo", [
        bb_doc("foo", "exact", [["/jobsearch", 1]], []),
        bb_doc("foo", "stemmed", [["/jobs", 1]], []),
      ])
    end

    should "find just the exact best bet" do
      assert_equal({1 => ["/jobsearch"]}, @checker.best_bets)
    end

    should "not find any worst bets" do
      assert_equal([], @checker.worst_bets)
    end
  end

  context "with two stemmed best bets" do
    setup do
      setup_checker("foo", [
        bb_doc("foo", "stemmed", [["/jobsearch", 1]], []),
        bb_doc("foo", "stemmed", [["/jobs", 1]], []),
      ])
    end

    should "find both best bets" do
      assert_equal({1 => ["/jobs", "/jobsearch"]}, @checker.best_bets)
    end

    should "not find any worst bets" do
      assert_equal([], @checker.worst_bets)
    end
  end

  context "with best bets with multiple links" do
    setup do
      setup_checker("foo", [
        bb_doc("foo", "stemmed", [["/jobsearch", 1], ["/jobs", 2]], []),
        bb_doc("foo", "stemmed", [["/jobs", 1], ["/working", 4]], []),
      ])
    end

    should "use highest position for all best bets" do
      assert_equal({
        1 => ["/jobs", "/jobsearch"],
        4 => ["/working"],
      }, @checker.best_bets)
    end

    should "not find any worst bets" do
      assert_equal([], @checker.worst_bets)
    end
  end

  context "with exact and stemmed bets which conflict" do
    setup do
      setup_checker("foo", [
        bb_doc("foo", "exact", [["/jobs", 4]], ["/jobsearch"]),
        bb_doc("foo", "stemmed", [["/jobsearch", 1], ["/jobs", 2]], ["/foo"]),
        bb_doc("foo", "stemmed", [["/jobs", 1], ["/working", 4]], []),
      ])
    end

    should "use just the positions from the exact bet" do
      assert_equal({
        4 => ["/jobs"],
      }, @checker.best_bets)
    end

    should "find worst bets only from the exact bet" do
      assert_equal(["/jobsearch"], @checker.worst_bets)
    end
  end

end
