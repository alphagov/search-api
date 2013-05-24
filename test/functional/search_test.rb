# encoding: utf-8
require "integration_test_helper"
require "organisation_registry"
require "topic_registry"

class SearchTest < IntegrationTest
  def mod_organisation
    Document.new(
      %w(link title),
      {
        link: "/government/organisations/ministry-of-defence",
        title: "Ministry of Defence (MoD)"
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

  def test_returns_json_for_search_results
    stub_index.expects(:search).returns(stub(results: [sample_document]))
    get "/search", {q: "bob"}, "HTTP_ACCEPT" => "application/json"
    assert_equal [sample_document_attributes], MultiJson.decode(last_response.body)
    assert_match(/application\/json/, last_response.headers["Content-Type"])
  end

  def test_returns_json_when_requested_with_url_suffix
    stub_index.expects(:search).returns(stub(results: [sample_document]))
    get "/search.json", {q: "bob"}
    assert_equal [sample_document_attributes], MultiJson.decode(last_response.body)
    assert_match(/application\/json/, last_response.headers["Content-Type"])
  end

  def test_handles_results_with_organisations
    mappings = default_mappings
    mappings["edition"]["properties"]["organisations"] = {"type" => "string"}
    document = Document.from_hash(
      sample_document_attributes.merge(organisations: ["ministry-of-defence"]),
      mappings
    )

    stub_index.expects(:search).returns(stub(results: [document]))
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

    stub_index.expects(:search).returns(stub(results: [document]))
    TopicRegistry.any_instance.expects(:[])
      .with("housing")
      .returns(housing_topic)
    get "/search.json", {q: "bob"}
    first_result = MultiJson.decode(last_response.body).first
    assert_equal 1, first_result["topics"].size
    assert_equal housing_topic.title, first_result["topics"][0]["title"]
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
