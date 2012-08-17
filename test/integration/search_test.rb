# encoding: utf-8
require "integration_test_helper"

class SearchTest < IntegrationTest
  def test_autocomplete_cache
    @primary_solr.stubs(:autocomplete_cache).returns([
      sample_document,
      sample_document
    ])
    get "/preload-autocomplete"
    assert last_response.ok?

    results = JSON.parse last_response.body
    assert_equal 2, results.size
  end

  #removing test for now - need to reinstate once new copy is available
  #def test_search_view_with_no_query
  #  get "/search"
  #  assert last_response.ok?
  #  assert_response_text "You haven’t specified a search query"
  #end

  def test_search_view_returning_no_results
    @primary_solr.stubs(:search).returns([])
    get "/search", {q: "bob"}
    assert last_response.ok?
    assert_response_text "we can’t find any results"
  end

  def test_we_pass_the_optional_filter_parameter_to_searches
    @primary_solr.expects(:search).with("anything", "my-format").returns([])
    get "/search", {q: "anything", format_filter: "my-format"}
  end

  def test_we_count_result
    @primary_solr.stubs(:search).returns([sample_document])
    @secondary_solr.stubs(:search).returns([])

    get "/search", {q: "bob"}

    assert last_response.ok?
    assert_response_text "1 result "
  end

  def test_we_count_results
    @primary_solr.stubs(:search).returns([sample_document, sample_document])
    @secondary_solr.stubs(:search).returns([])

    get "/search", {q: "bob"}

    assert last_response.ok?
    assert_response_text "2 results"
  end

  def test_should_return_autocompletion_documents_as_json
    @primary_solr.stubs(:complete).returns([sample_document])
    get "/autocomplete", {q: "bob"}
    assert last_response.ok?
    assert_equal [sample_document_attributes], JSON.parse(last_response.body)
  end

  def test_we_pass_the_optional_filter_parameter_to_autocomplete
    @primary_solr.expects(:complete).with("anything", "my-format").returns([])
    get "/autocomplete", {q: "anything", format_filter: "my-format"}
  end

  def test_should_send_analytics_headers_for_citizen_proposition
    @primary_solr.stubs(:search).returns([])
    get "/search", {q: "bob"}
    assert_equal "search",  last_response.headers["X-Slimmer-Section"]
    assert_equal "search",  last_response.headers["X-Slimmer-Format"]
    assert_equal "citizen", last_response.headers["X-Slimmer-Proposition"]
    assert_equal "0", last_response.headers["X-Slimmer-Result-Count"]
  end

  def test_result_count_header_with_results
    @primary_solr.stubs(:search).returns(Array.new(15, sample_document))
    @secondary_solr.stubs(:search).returns([])

    get "/search", {q: "bob"}

    assert_equal "15", last_response.headers["X-Slimmer-Result-Count"]
  end

  def test_should_send_analytics_headers_for_government_proposition
    app.settings.stubs(:slimmer_headers).returns(
      section:     "Search",
      format:      "search",
      proposition: "government"
    )
    @primary_solr.stubs(:search).returns([])
    get "/search", {q: "bob"}
    assert_equal "government", last_response.headers["X-Slimmer-Proposition"]
    # Make sure the result count works for government too
    assert_equal "0", last_response.headers["X-Slimmer-Result-Count"]
  end

  def test_should_set_body_class_based_on_proposition_header
    app.settings.stubs(:slimmer_headers).returns(
      section:     "x",
      format:      "y",
      proposition: "blah"
    )
    @primary_solr.stubs(:search).returns([])
    get "/search", {q: "bob"}
    # the mainstream class is temporarily hardcoded while we switch to using it
    assert_match /<body class="blah mainstream"/, last_response.body
  end

  def test_should_respond_with_json_when_requested
    @primary_solr.stubs(:search).returns([
      sample_document
    ])
    get "/search", {q: "bob"}, "HTTP_ACCEPT" => "application/json"
    assert_equal [sample_document_attributes.merge("highlight"=>"DESCRIPTION")], JSON.parse(last_response.body)
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

  def test_should_respond_with_json_when_requested_with_url_suffix
    @primary_solr.stubs(:search).returns([
      sample_document
    ])
    get "/search.json", {q: "bob"}
    assert_equal [sample_document_attributes.merge("highlight"=>"DESCRIPTION")], JSON.parse(last_response.body)
    assert_match /application\/json/, last_response.headers["Content-Type"]
  end

  def test_should_ignore_edge_spaces_and_codepoints_below_0x20
    @primary_solr.expects(:search).never
    get "/search", {q: " \x02 "}
    assert_no_match /we can’t find any results/, last_response.body
  end

  def test_should_not_blow_up_with_a_result_wihout_a_section
    @primary_solr.stubs(:search).returns([
      Document.from_hash({
        "title" => "TITLE1",
        "description" => "DESCRIPTION",
        "format" => "local_transaction",
        "link" => "/URL"
      })
    ])
    @secondary_solr.stubs(:search).returns([])

    assert_nothing_raised do
      get "/search", {q: "bob"}
    end
  end

  def test_should_not_allow_xss_vulnerabilites_as_search_terms
    @primary_solr.stubs(:search).returns([])
    get "/search", {q: "1+\"><script+src%3Dhttp%3A%2F%2F88.151.219.231%2F4><%2Fscript>"}

    assert_response_text "Sorry, we can’t find any results for"
    assert_match "\"1+&quot;&gt;&lt;script+src%3Dhttp%3A%2F%2F88.151.219.231%2F4&gt;&lt;%2Fscript&gt;\"", last_response.body
  end

  def test_should_not_show_secondary_solr_guidance_filter_when_no_secondary_solr_results_present
    @primary_solr.stubs(:search).returns([sample_document, sample_document])
    @secondary_solr.stubs(:search).returns([])

    get "/search", {q: "1.21 gigawatts?!"}

    assert last_response.ok?
    assert_response_text "2 results"
    assert_equal false, last_response.body.include?("Specialist guidance")
  end

  def test_should_show_secondary_solr_guidance_filter_when_secondary_solr_results_exist
    settings.stubs(:feature_flags).returns({:use_secondary_solr_index => true})

    @primary_solr.stubs(:search).returns([sample_document])
    @secondary_solr.stubs(:search).returns([sample_document])

    get "/search", {q: "Are you telling me that you built a time machine... out of a DeLorean?"}

    assert last_response.ok?
    assert_equal true, last_response.body.include?("Specialist guidance")
  end

  def test_should_include_secondary_solr_results_when_provided_results_count
    settings.stubs(:feature_flags).returns({:use_secondary_solr_index => true})

    @primary_solr.stubs(:search).returns([sample_document])
    @secondary_solr.stubs(:search).returns([sample_document])

    get "/search", {q: "If my calculations are correct, when this baby hits 88 miles per hour... you're gonna see some serious shit."}

    assert last_response.ok?
    assert_response_text "2 results"
  end

  def test_should_show_secondary_solr_results_count_next_to_secondary_solr_filter
    settings.stubs(:feature_flags).returns({:use_secondary_solr_index => true})

    @primary_solr.stubs(:search).returns([sample_document])
    @secondary_solr.stubs(:search).returns([sample_document])

    get "/search", {q: "This is heavy."}

    assert last_response.ok?
    assert_match "Specialist guidance <span>1</span>", last_response.body
  end

  def test_should_show_secondary_solr_results_after_the_primary_solr_results
    settings.stubs(:feature_flags).returns({:use_secondary_solr_index => true})

    example_secondary_solr_result = {
      "title" => "Back to the Future",
      "description" => "In 1985, Doc Brown invents time travel; in 1955, Marty McFly accidentally prevents his parents from meeting, putting his own existence at stake.",
      "format" => "local_transaction",
      "section" => "de-lorean",
      "link" => "/1-21-gigawatts"
    }

    @primary_solr.stubs(:search).returns([sample_document])
    @secondary_solr.stubs(:search).returns([Document.from_hash(example_secondary_solr_result)])

    get "/search", {q: "Hey, Doc, we better back up. We don't have enough road to get up to 88.\nRoads? Where we're going, we don't need roads"}

    assert last_response.ok?
    assert_match "<li class=\"section-specialist type-local_transaction\">", last_response.body
    assert_match "<p class=\"search-result-title\"><a href=\"/1-21-gigawatts\" title=\"View Back to the Future\">Back to the Future</a></p>", last_response.body
    assert_match "<p>In 1985, Doc Brown invents time travel; in 1955, Marty McFly accidentally prevents his parents from meeting, putting his own existence at stake.</p>", last_response.body
    assert_match "<a href=\"/browse/de-lorean\">De lorean</a><", last_response.body
  end

  def test_should_limit_results
    settings.stubs(:feature_flags).returns({use_secondary_solr_index: true})

    example_secondary_solr_result = {
      "title" => "Back to the Future",
      "description" => "In 1985, Doc Brown invents time travel; in 1955, Marty McFly accidentally prevents his parents from meeting, putting his own existence at stake.",
      "format" => "local_transaction",
      "section" => "de-lorean",
      "link" => "/1-21-gigawatts"
    }

    @primary_solr.stubs(:search).returns(Array.new(75, sample_document))
    @secondary_solr.stubs(:search).returns([])

    get :search, {q: "Test"}

    assert_response_text "50 results"
    assert_match "<span>50</span>", last_response.body
  end

  def test_should_only_show_limited_main_and_limited_secondary_results
    settings.stubs(:feature_flags).returns({use_secondary_solr_index: true})

    example_secondary_solr_result = {
      "title" => "Back to the Future",
      "description" => "In 1985, Doc Brown invents time travel; in 1955, Marty McFly accidentally prevents his parents from meeting, putting his own existence at stake.",
      "format" => "local_transaction",
      "section" => "de-lorean",
      "link" => "/1-21-gigawatts"
    }

    @primary_solr.stubs(:search).returns(Array.new(52, sample_document))
    @secondary_solr.stubs(:search).returns(Array.new(7, Document.from_hash(example_secondary_solr_result)))

    get :search, {q: "Test"}

    assert_response_text "50 results"
    assert_match "<span>45</span>", last_response.body # TODO: how do I test the life in the UK thing?
    assert_match "Specialist guidance <span>5</span>", last_response.body
  end

  def test_should_show_external_links_with_a_separate_list_class
    external_document = Document.from_hash({
      "title" => "A title",
      "description" => "This is a description",
      "format" => "recommended-link",
      "link" => "http://twitter.com",
      "section" => "driving"
    })

    @primary_solr.stubs(:search).returns([external_document])

    get :search, {q: "bleh"}

    assert last_response.ok?
    assert_response_text "1 result"
    assert_match "Driving <span>1</span>", last_response.body
    assert_match "<li class=\"section-driving type-guide external\">", last_response.body
    assert_match "rel=\"external\"", last_response.body
  end
end
