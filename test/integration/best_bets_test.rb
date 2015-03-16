require "integration_test_helper"
require "rest-client"
require_relative "multi_index_test"

class BestBetsTest < MultiIndexTest
  METASEARCH_INDEX_NAME = "metasearch_test"

  def setup
    super
    setup_metasearch_index
  end

  def teardown
    super
    clean_index_group(METASEARCH_INDEX_NAME)
  end

  def sample_bet(query, type, best_bets, worst_bets)
    {
      "#{type}_query" => query,
      details: JSON.generate(
        {
          best_bets: best_bets,
          worst_bets: worst_bets,
        }
      ),
      _type: "best_bet",
      _id: "#{query}-#{type}",
    }
  end

  def sample_bets
    [
      sample_bet("forced best bet", "exact",
                 [{link: "/mainstream-1", position: 1}], []),
      sample_bet("important content", "exact",
                 [], [{link: "/mainstream-1"}]),
      sample_bet("forced best", "stemmed",
                 [
                   {link: "/mainstream-1", position: 2},
                   {link: "/mainstream-2", position: 3},
                 ], []),
      sample_bet("best bet", "stemmed",
                 [
                   {link: "/mainstream-2", position: 1},
                 ], []),
      sample_bet("jobs", "stemmed",
                 [
                   {link: "/mainstream-1", position: 1},
                 ], []),
    ]
  end

  def add_sample_bets(bets) 
    bets.each do |doc|
      post "/#{METASEARCH_INDEX_NAME}/documents", doc.to_json
      assert last_response.ok?
    end
    commit_index(METASEARCH_INDEX_NAME)
  end

  def setup_metasearch_index
    try_remove_test_index(METASEARCH_INDEX_NAME)
    create_test_index(METASEARCH_INDEX_NAME)
    add_sample_bets(sample_bets)
  end

  def get_links(path)
    get path
    links = parsed_response["results"].map { |result| result["link"] }
    get(path + "&debug=disable_best_bets")
    no_bb_links = parsed_response["results"].map { |result| result["link"] }
    [links, no_bb_links]
  end

  def test_exact_best_bet
    links, no_bb_links = get_links "/unified_search?q=forced+best+bet"

    assert_equal ["/mainstream-1"], links
    assert_equal [], no_bb_links
  end

  def test_exact_worst_bet
    links, no_bb_links = get_links "/unified_search?q=important+content"

    assert !(links.include? "/mainstream-1")
    assert no_bb_links.include? "/mainstream-1"
  end

  def test_stemmed_best_bet
    links, no_bb_links = get_links "/unified_search?q=forced+best"

    assert_equal ["/mainstream-1", "/mainstream-2"], links
    assert_equal [], no_bb_links
  end

  def test_stemmed_variant_best_bet
    links, no_bb_links = get_links "/unified_search?q=forced+bests"

    assert_equal ["/mainstream-1", "/mainstream-2"], links
    assert_equal [], no_bb_links
  end

  def test_stemmed_best_bet_words_not_in_phrase_order
    # A stemmed best bet shouldn't get used if the terms were in the wrong
    # order
    links, no_bb_links = get_links "/unified_search?q=best+forced"

    assert_equal [], links
    assert_equal [], no_bb_links
  end

  def test_combined_stemmed_best_bets
    links, no_bb_links = get_links "/unified_search?q=forced+best+bets"

    assert_equal ["/mainstream-2", "/mainstream-1"], links
    assert_equal [], no_bb_links
  end

  def test_stemmed_best_bet_matches_exact_search
    links, no_bb_links = get_links "/unified_search?q=jobs"

    assert_equal ["/mainstream-1"], links
    assert_equal [], no_bb_links
  end

  def test_stemmed_best_bet_matches_larger_search
    links, no_bb_links = get_links "/unified_search?q=jobs+site"

    assert_equal ["/mainstream-1"], links
    assert_equal [], no_bb_links
  end

end
