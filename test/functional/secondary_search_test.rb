# encoding: utf-8
require "integration_test_helper"

class SecondarySearchTest < IntegrationTest

  def setup
    super
    stub_primary_and_secondary_searches
  end

  def test_should_not_show_secondary_solr_guidance_filter_when_no_secondary_solr_results_present
    @primary_search.stubs(:search).returns([sample_document, sample_document])
    @secondary_search.stubs(:search).returns([])

    get "/search", {q: "1.21 gigawatts?!"}

    assert last_response.ok?
    assert_response_text "2 results"
    assert_equal false, last_response.body.include?("Specialist guidance")
  end

  def test_should_show_secondary_solr_guidance_filter_when_secondary_solr_results_exist
    @primary_search.stubs(:search).returns([sample_document])
    @secondary_search.stubs(:search).returns([sample_document])

    get "/search", {q: "Are you telling me that you built a time machine... out of a DeLorean?"}

    assert last_response.ok?
    assert_equal true, last_response.body.include?("Specialist guidance")
  end

  def test_should_include_secondary_solr_results_when_provided_results_count
    @primary_search.stubs(:search).returns([sample_document])
    @secondary_search.stubs(:search).returns([sample_document])

    get "/search", {q: "If my calculations are correct, when this baby hits 88 miles per hour... you're gonna see some serious shit."}

    assert last_response.ok?
    assert_response_text "2 results"
  end

  def test_should_include_secondary_results_in_json_response
    @primary_search.stubs(:search).returns([sample_document])
    sample_specialist_document = sample_document.tap do |document|
      document.link = "/specialist-link"
    end
    @secondary_search.stubs(:search).returns([sample_specialist_document])

    get "/search.json", q: "Not a quote from Back To The Future"
    assert last_response.ok?
    assert_equal(
      [sample_document.link, "/specialist-link"],
      JSON.parse(last_response.body).map { |r| r["link"] }
    )
  end

  def test_should_show_secondary_solr_results_count_next_to_secondary_solr_filter
    @primary_search.stubs(:search).returns([sample_document])
    @secondary_search.stubs(:search).returns([sample_document])

    get "/search", {q: "This is heavy."}

    assert last_response.ok?
    assert_match "Specialist guidance <span>1</span>", last_response.body
  end

  def test_should_show_secondary_solr_results_after_the_primary_solr_results
    example_secondary_solr_result = {
      "title" => "Back to the Future",
      "description" => "In 1985, Doc Brown invents time travel; in 1955, Marty McFly accidentally prevents his parents from meeting, putting his own existence at stake.",
      "format" => "local_transaction",
      "section" => "de-lorean",
      "link" => "/1-21-gigawatts"
    }

    @primary_search.stubs(:search).returns([sample_document])
    @secondary_search.stubs(:search).returns([Document.from_hash(example_secondary_solr_result)])

    get "/search", {q: "Hey, Doc, we better back up. We don't have enough road to get up to 88.\nRoads? Where we're going, we don't need roads"}

    assert last_response.ok?
    assert_match "<li class=\"section-specialist type-local_transaction\">", last_response.body
    assert_match "<p class=\"search-result-title\"><a href=\"/1-21-gigawatts\" title=\"View Back to the Future\">Back to the Future</a></p>", last_response.body
    assert_match "<p>In 1985, Doc Brown invents time travel; in 1955, Marty McFly accidentally prevents his parents from meeting, putting his own existence at stake.</p>", last_response.body
    assert_match "<a href=\"/browse/de-lorean\">De lorean</a><", last_response.body
  end

  def test_should_limit_results
    example_secondary_solr_result = {
      "title" => "Back to the Future",
      "description" => "In 1985, Doc Brown invents time travel; in 1955, Marty McFly accidentally prevents his parents from meeting, putting his own existence at stake.",
      "format" => "local_transaction",
      "section" => "de-lorean",
      "link" => "/1-21-gigawatts"
    }

    @primary_search.stubs(:search).returns(Array.new(75, sample_document))
    @secondary_search.stubs(:search).returns([])

    get :search, {q: "Test"}

    assert_response_text "50 results"
    assert_match "<span>50</span>", last_response.body
  end

  def test_should_only_show_limited_main_and_limited_secondary_results
    example_secondary_solr_result = {
      "title" => "Back to the Future",
      "description" => "In 1985, Doc Brown invents time travel; in 1955, Marty McFly accidentally prevents his parents from meeting, putting his own existence at stake.",
      "format" => "local_transaction",
      "section" => "de-lorean",
      "link" => "/1-21-gigawatts"
    }

    @primary_search.stubs(:search).returns(Array.new(52, sample_document))
    @secondary_search.stubs(:search).returns(Array.new(7, Document.from_hash(example_secondary_solr_result)))

    get :search, {q: "Test"}

    assert_response_text "50 results"
    assert_match "<span>45</span>", last_response.body # TODO: how do I test the life in the UK thing?
    assert_match "Specialist guidance <span>5</span>", last_response.body
  end
end
