# encoding: utf-8
require "integration_test_helper"
require 'document_series_registry'
require "organisation_registry"
require "topic_registry"
require "world_location_registry"

class SearchTest < IntegrationTest

  def bus_timetables_document_series
    Document.new(
      %w(link title),
      {
        link: "/government/organisations/department-for-transport/series/bus-timetables",
        title: "Bus Timetables"
      }
    )
  end

  def angola_world_location
    Document.new(
      %w(link title),
      {
        link: "/government/world/angola",
        title: "Angola"
      }
    )
  end

  def mod_organisation
    Document.new(
      %w(link title),
      {
        link: "/government/organisations/ministry-of-defence",
        title: "Ministry of Defence (MoD)"
      }
    )
  end

  def dft_organisation
    Document.new(
      %w(link title acronym),
      {
        link: "/government/organisations/department-for-transport",
        title: "Department for Transport",
        acronym: "DFT"
      }
    )
  end

  def housing_topic
    Document.new(
      %w(link title),
      {
        link: "/government/topics/housing",
        title: "Housing"
      }
    )
  end

  def setup
    OrganisationRegistry.any_instance.stubs(:all).returns([])
  end

  def test_returns_json_for_search_results
    stub_index.expects(:search).returns(stub(results: [sample_document], total: 1))
    get "/search", {q: "bob"}, "HTTP_ACCEPT" => "application/json"
    assert_equal [sample_document_attributes], MultiJson.decode(last_response.body)
    assert_match(/application\/json/, last_response.headers["Content-Type"])
  end

  def test_returns_json_when_requested_with_url_suffix
    stub_index.expects(:search).returns(stub(results: [sample_document], total: 1))
    get "/search.json", {q: "bob"}
    assert_equal [sample_document_attributes], MultiJson.decode(last_response.body)
    assert_match(/application\/json/, last_response.headers["Content-Type"])
  end

  def test_returns_spelling_suggestions_when_hash_requested
    stub_index.expects(:search).returns(stub(results: [], total: 0))
    get "/search.json", {q: "speling", response_style: "hash"}
    assert_equal ["spelling"], MultiJson.decode(last_response.body)["spelling_suggestions"]
  end

  def test_does_not_suggest_corrections_for_organisation_acronyms
    stub_index.expects(:search).returns(stub(results: [], total: 0))
    OrganisationRegistry.any_instance.expects(:all)
      .returns([dft_organisation])
    get "/search.json", {q: "DFT", response_style: "hash"} # DFT would get a suggestion
    assert_equal [], MultiJson.decode(last_response.body)["spelling_suggestions"]
  end

  def test_matches_organisation_acronyms_in_any_letter_case
    stub_index.expects(:search).returns(stub(results: [], total: 0))
    OrganisationRegistry.any_instance.expects(:all)
      .returns([dft_organisation])
    get "/search.json", {q: "dft", response_style: "hash"} # DFT would get a suggestion
    assert_equal [], MultiJson.decode(last_response.body)["spelling_suggestions"]
  end

  def test_handles_organisations_without_acronyms_for_suggestions
    organisation_without_acronym = Document.new(
      %w(link title acronym),
      {
        link: "/government/organisations/acronymless-department",
        title: "Acronymless Department"
      }
    )

    stub_index.expects(:search).returns(stub(results: [], total: 0))
    OrganisationRegistry.any_instance.expects(:all)
      .returns([organisation_without_acronym])
    get "/search.json", {q: "pies", response_style: "hash"}
    assert_equal [], MultiJson.decode(last_response.body)["spelling_suggestions"]
  end

  def test_does_not_suggest_corrections_for_words_in_ignore_file
    stub_index.expects(:search).returns(stub(results: [], total: 0))
    get "/search.json", {q: "sorn", response_style: "hash"} # sorn would get a suggestion
    assert_equal [], MultiJson.decode(last_response.body)["spelling_suggestions"]
  end

  def test_does_not_suggest_corrections_for_numbers_or_words_containing_numbers
    stub_index.expects(:search).returns(stub(results: [], total: 0))
    get "/search.json", {q: "v5c 2013", response_style: "hash"} # v5c would get a suggestion
    assert_equal [], MultiJson.decode(last_response.body)["spelling_suggestions"]
  end

  def test_does_not_suggest_corrections_in_blacklist_file
    stub_index.expects(:search).returns(stub(results: [], total: 0))
    get "/search.json", {q: "penison", response_style: "hash"} # penison would get an inappropriate suggestion
    assert_equal ["pension"], MultiJson.decode(last_response.body)["spelling_suggestions"]
  end

  def test_handles_results_with_document_series
    mappings = default_mappings
    mappings["edition"]["properties"]["document_series"] = {"type" => "string"}
    document = Document.from_hash(
      sample_document_attributes.merge(document_series: ["bus-timetables"]),
      mappings
    )

    stub_index.expects(:search).returns(stub(results: [document], total: 1))
    DocumentSeriesRegistry.any_instance.expects(:[])
      .with("bus-timetables")
      .returns(bus_timetables_document_series)
    get "/search.json", {q: "bob"}
    first_result = MultiJson.decode(last_response.body).first
    assert_equal 1, first_result["document_series"].size
    assert_equal bus_timetables_document_series.title, first_result["document_series"][0]["title"]
  end

  def test_handles_results_with_organisations
    mappings = default_mappings
    mappings["edition"]["properties"]["organisations"] = {"type" => "string"}
    document = Document.from_hash(
      sample_document_attributes.merge(organisations: ["ministry-of-defence"]),
      mappings
    )

    stub_index.expects(:search).returns(stub(results: [document], total: 1))
    OrganisationRegistry.any_instance.expects(:[])
      .with("ministry-of-defence")
      .returns(mod_organisation)
    get "/search.json", {q: "bob"}
    first_result = MultiJson.decode(last_response.body).first
    assert_equal 1, first_result["organisations"].size
    assert_equal mod_organisation.title, first_result["organisations"][0]["title"]
  end

  def test_handles_results_with_topics
    mappings = default_mappings
    mappings["edition"]["properties"]["topics"] = {"type" => "string"}
    document = Document.from_hash(
      sample_document_attributes.merge(topics: ["housing"]),
      mappings
    )

    stub_index.expects(:search).returns(stub(results: [document], total: 1))
    TopicRegistry.any_instance.expects(:[])
      .with("housing")
      .returns(housing_topic)
    get "/search.json", {q: "bob"}
    first_result = MultiJson.decode(last_response.body).first
    assert_equal 1, first_result["topics"].size
    assert_equal housing_topic.title, first_result["topics"][0]["title"]
  end

  def test_handles_results_with_world_locations
    mappings = default_mappings
    mappings["edition"]["properties"]["world_locations"] = {"type" => "string"}
    document = Document.from_hash(
      sample_document_attributes.merge(world_locations: ["angola"]),
      mappings
    )

    stub_index.expects(:search).returns(stub(results: [document], total: 1))
    WorldLocationRegistry.any_instance.expects(:[])
      .with("angola")
      .returns(angola_world_location)
    get "/search.json", {q: "bob"}
    first_result = MultiJson.decode(last_response.body).first
    assert_equal 1, first_result["world_locations"].size
    assert_equal angola_world_location.title, first_result["world_locations"][0]["title"]
  end

  def test_returns_404_when_requested_with_non_json_url
    stub_index.expects(:search).never
    get "/search.xml", {q: "bob"}
    assert last_response.not_found?
  end

  def test_should_ignore_edge_spaces_and_codepoints_below_0x20
    stub_index.expects(:search).never
    get "/search", {q: " \x02 "}
    refute_match(/we can’t find any results/, last_response.body)
  end

  def test_returns_404_for_empty_queries
    stub_index.expects(:search).never
    get "/search"
    assert last_response.not_found?
  end
end
