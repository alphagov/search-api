# encoding: utf-8
require "integration_test_helper"

class SecondarySearchTest < IntegrationTest

  def setup
    super
    stub_primary_and_secondary_searches
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



end
