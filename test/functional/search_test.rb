# encoding: utf-8
require "integration_test_helper"
require "registry"

class SearchTest < IntegrationTest

  def setup
    super
    stub_elasticsearch_settings
    Registry::Organisation.any_instance.stubs(:all).returns([])
  end

  def bus_timetables_document_series
    Document.new(
      sample_document_types["edition"].fields,
      {
        link: "/government/organisations/department-for-transport/series/bus-timetables",
        title: "Bus Timetables"
      }
    )
  end

  def learning_to_drive_document_collection
    Document.new(
      sample_document_types["edition"].fields,
      {
        link: "/government/collections/learning-to-drive",
        title: "Learning to Drive"
      }
    )
  end

  def angola_world_location
    Document.new(
      sample_document_types["edition"].fields,
      {
        link: "/government/world/angola",
        title: "Angola"
      }
    )
  end

  def oil_gas_sector_fields
    {
      "link" => "/oil-and-gas/licensing",
      "title" => "Licensing",
      "slug" => "oil-and-gas/licensing",
    }
  end

  def mod_organisation
    Document.new(
      sample_document_types["edition"].fields,
      {
        link: "/government/organisations/ministry-of-defence",
        title: "Ministry of Defence (MoD)"
      }
    )
  end

  def dft_organisation
    Document.new(
      sample_document_types["edition"].fields,
      {
        link: "/government/organisations/department-for-transport",
        title: "Department for Transport",
        acronym: "DFT"
      }
    )
  end

  def housing_topic
    Document.new(
      sample_document_types["edition"].fields,
      {
        link: "/government/topics/housing",
        title: "Housing"
      }
    )
  end

  def example_people
    Document.new(
      sample_document_types["edition"].fields,
      {
        link: "/government/people/example-people",
        title: "Example Person"
      }
    )
  end

  def test_returns_json_for_search_results
    stub_index.expects(:search).returns(stub(results: [sample_document], total: 1))
    get "/search", {q: "bob"}, "HTTP_ACCEPT" => "application/json"
    assert_equal [sample_document_attributes], JSON.parse(last_response.body)["results"]
    assert_match(/application\/json/, last_response.headers["Content-Type"])
  end

  def test_returns_semantic_response_for_invalid_query
    get "/mainstream_test/search", { q: "bob", sort: "not_in_schema" }
    assert_equal 422, last_response.status
    assert_equal "Sorting on unknown property: not_in_schema", last_response.body
  end

  def test_returns_json_when_requested_with_url_suffix
    stub_index.expects(:search).returns(stub(results: [sample_document], total: 1))
    get "/search.json", {q: "bob"}
    assert_equal [sample_document_attributes], JSON.parse(last_response.body)["results"]
    assert_match(/application\/json/, last_response.headers["Content-Type"])
  end

  def test_handles_results_with_document_series
    document = Document.from_hash(
      sample_document_attributes.merge(document_series: ["bus-timetables"]),
      sample_document_types
    )

    stub_index.expects(:search).returns(stub(results: [document], total: 1))
    Registry::DocumentSeries.any_instance.expects(:[])
      .with("bus-timetables")
      .returns(bus_timetables_document_series)
    get "/search.json", {q: "bob"}
    first_result = JSON.parse(last_response.body)["results"].first
    assert_equal 1, first_result["document_series"].size
    assert_equal bus_timetables_document_series.title, first_result["document_series"][0]["title"]
  end

  def test_handles_results_with_document_collections
    document = Document.from_hash(
      sample_document_attributes.merge(document_collections: ["learning-to-drive"]),
      sample_document_types
    )

    stub_index.expects(:search).returns(stub(results: [document], total: 1))
    Registry::DocumentCollection.any_instance.expects(:[])
      .with("learning-to-drive")
      .returns(learning_to_drive_document_collection)
    get "/search.json", {q: "bob"}
    first_result = JSON.parse(last_response.body)["results"].first
    assert_equal 1, first_result["document_collections"].size
    assert_equal learning_to_drive_document_collection.title, first_result["document_collections"][0]["title"]
  end

  def test_handles_results_with_organisations
    document = Document.from_hash(
      sample_document_attributes.merge(organisations: ["ministry-of-defence"]),
      sample_document_types
    )

    stub_index.expects(:search).returns(stub(results: [document], total: 1))
    Registry::Organisation.any_instance.expects(:[])
      .with("ministry-of-defence")
      .returns(mod_organisation)
    get "/search.json", {q: "bob"}
    first_result = JSON.parse(last_response.body)["results"].first
    assert_equal 1, first_result["organisations"].size
    assert_equal mod_organisation.title, first_result["organisations"][0]["title"]
  end

  def test_handles_results_with_topics
    document = Document.from_hash(
      sample_document_attributes.merge(topics: ["housing"]),
      sample_document_types
    )

    stub_index.expects(:search).returns(stub(results: [document], total: 1))
    Registry::Topic.any_instance.expects(:[])
      .with("housing")
      .returns(housing_topic)
    get "/search.json", {q: "bob"}
    first_result = JSON.parse(last_response.body)["results"].first
    assert_equal 1, first_result["topics"].size
    assert_equal housing_topic.title, first_result["topics"][0]["title"]
  end

  def test_handles_results_with_world_locations
    document = Document.from_hash(
      sample_document_attributes.merge(world_locations: ["angola"]),
      sample_document_types
    )

    stub_index.expects(:search).returns(stub(results: [document], total: 1))
    Registry::WorldLocation.any_instance.expects(:[])
      .with("angola")
      .returns(angola_world_location)
    get "/search.json", {q: "bob"}
    first_result = JSON.parse(last_response.body)["results"].first
    assert_equal 1, first_result["world_locations"].size
    assert_equal angola_world_location.title, first_result["world_locations"][0]["title"]
  end

  def test_handles_results_with_sectors
    mappings = default_mappings
    mappings["edition"]["properties"]["specialist_sectors"] = {"type" => "string"}
    document = {
      "_index" => "mainstream",
      "_id" => "foo_id",
      "_score" => "1.0",
      "_type" => "edition",
      "fields" => sample_document_attributes.merge("specialist_sectors" => ["oil-and-gas/licensing"])
    }

    stub_index.stubs(:schema).returns(sample_schema)
    stub_index.stubs(:mappings).returns(mappings)
    stub_index.expects(:raw_search).returns({"hits" => {"hits" => [document], "total" => 1}})
    stub_metasearch_index.expects(:analyzed_best_bet_query).with("bob").returns("bob")
    stub_metasearch_index.expects(:raw_search).returns({"hits" => {"hits" => []}})
    Registry::SpecialistSector.any_instance.expects(:[])
      .with("oil-and-gas/licensing")
      .returns(oil_gas_sector_fields)

    # Stub the spell check-request.
    stub_elasticsearch_request('/mainstream_test,detailed_test,government_test/_search' => {})

    get "/unified_search.json", {q: "bob"}

    first_result = JSON.parse(last_response.body)["results"].first
    assert_equal 1, first_result["specialist_sectors"].size
    assert_equal oil_gas_sector_fields["title"], first_result["specialist_sectors"][0]["title"]
    assert_equal oil_gas_sector_fields["link"], first_result["specialist_sectors"][0]["link"]
    assert_equal oil_gas_sector_fields["slug"], first_result["specialist_sectors"][0]["slug"]
  end

  def test_handles_results_with_people
    document = Document.from_hash(
      sample_document_attributes.merge(people: ["example-people"]),
      sample_document_types
    )

    stub_index.expects(:search).returns(stub(results: [document], total: 1))
    Registry::Person.any_instance.expects(:[])
      .with("example-people")
      .returns(example_people)
    get "/search.json", {q: "bob"}
    first_result = JSON.parse(last_response.body)["results"].first
    assert_equal 1, first_result["people"].size
    assert_equal example_people.title, first_result["people"][0]["title"]
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

  def test_returns_503_when_elasticsearch_timesout
    stub_index.expects(:search).raises(RestClient::RequestTimeout)
    get "/search.json", { q: "search term" }
    assert_equal 503, last_response.status
  end
end
