require 'spec_helper'

RSpec.describe Search::BestBetsChecker do
  def best_bets_query(query)
    {
      query: {
        bool: {
          should: [
            { match: { exact_query: query } },
            { match: { stemmed_query: query } }
          ]
        }
      },
      size: 1000,
      fields: [:details, :stemmed_query_as_term],
    }
  end

  def bb_hits(hits)
    { "hits" => { "hits" => hits, "total" => hits.length } }
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
            { link: link, position: position }
          end,
          worst_bets: worst_bets.map do |link|
            { link: link }
          end,
        })
      }
    }
  end

  def setup_checker(query, hits)
    @index = double("metasearch index")
    @checker = described_class.new(query, @index)
    expect(@index).to receive(:raw_search).with(
      best_bets_query(query), "best_bet"
    ).and_return(
      bb_hits(hits)
    )
    expect(@index).to receive(:analyzed_best_bet_query).with(query).and_return(query)
  end

  context "without best bets" do
    before do
      setup_checker("foo", [])
    end

    it "not find any best bets" do
      assert_equal({}, @checker.best_bets)
    end

    it "not find any worst bets" do
      assert_equal([], @checker.worst_bets)
    end
  end

  context "with an exact best bet" do
    before do
      setup_checker("foo", [
        bb_doc("foo", "exact", [["/jobsearch", 1]], [])
      ])
    end

    it "find one best bet" do
      assert_equal({ 1 => ["/jobsearch"] }, @checker.best_bets)
    end

    it "not find any worst bets" do
      assert_equal([], @checker.worst_bets)
    end
  end

  context "with an exact worst bet" do
    before do
      setup_checker("foo", [
        bb_doc("foo", "exact", [], ["/jobsearch"])
      ])
    end

    it "not find any best bets" do
      assert_equal({}, @checker.best_bets)
    end

    it "find one worst bet" do
      assert_equal(["/jobsearch"], @checker.worst_bets)
    end
  end

  context "with an exact and a stemmed best bet" do
    before do
      setup_checker("foo", [
        bb_doc("foo", "exact", [["/jobsearch", 1]], []),
        bb_doc("foo", "stemmed", [["/jobs", 1]], []),
      ])
    end

    it "find just the exact best bet" do
      assert_equal({ 1 => ["/jobsearch"] }, @checker.best_bets)
    end

    it "not find any worst bets" do
      assert_equal([], @checker.worst_bets)
    end
  end

  context "with two stemmed best bets" do
    before do
      setup_checker("foo", [
        bb_doc("foo", "stemmed", [["/jobsearch", 1]], []),
        bb_doc("foo", "stemmed", [["/jobs", 1]], []),
      ])
    end

    it "find both best bets" do
      assert_equal({ 1 => ["/jobs", "/jobsearch"] }, @checker.best_bets)
    end

    it "not find any worst bets" do
      assert_equal([], @checker.worst_bets)
    end
  end

  context "with best bets with multiple links" do
    before do
      setup_checker("foo", [
        bb_doc("foo", "stemmed", [["/jobsearch", 1], ["/jobs", 2]], []),
        bb_doc("foo", "stemmed", [["/jobs", 1], ["/working", 4]], []),
      ])
    end

    it "use highest position for all best bets" do
      assert_equal({
        1 => ["/jobs", "/jobsearch"],
        4 => ["/working"],
      }, @checker.best_bets)
    end

    it "not find any worst bets" do
      assert_equal([], @checker.worst_bets)
    end
  end

  context "with exact and stemmed bets which conflict" do
    before do
      setup_checker("foo", [
        bb_doc("foo", "exact", [["/jobs", 4]], ["/jobsearch"]),
        bb_doc("foo", "stemmed", [["/jobsearch", 1], ["/jobs", 2]], ["/foo"]),
        bb_doc("foo", "stemmed", [["/jobs", 1], ["/working", 4]], []),
      ])
    end

    it "use just the positions from the exact bet" do
      assert_equal({
        4 => ["/jobs"],
      }, @checker.best_bets)
    end

    it "find worst bets only from the exact bet" do
      assert_equal(["/jobsearch"], @checker.worst_bets)
    end
  end
end
