require "test_helper"
require "document"
require "result_set_presenter"

class ResultSetPresenterTest < MiniTest::Unit::TestCase

  FIELDS = %w(link title description format organisations topics document_series document_collections world_locations specialist_sectors people)

  # Tests

  def test_generates_json_from_documents
    presenter = ResultSetPresenter.new(result_set)
    output = presenter.present
    assert_equal 1, output["results"].length
    # Check all the fields from the document are present
    assert_equal [], %w(link title description format) - output["results"][0].keys
  end

  def test_expands_document_series
    rail_statistics_document = Document.new(
      sample_field_definitions(%w(link title)),
      link: "/government/organisations/department-for-transport/series/rail-statistics",
      title: "Rail statistics"
    )
    document_series_registry = stub("document series registry")
    document_series_registry.expects(:[])
      .with("rail-statistics")
      .returns(rail_statistics_document)

    presenter = ResultSetPresenter.new(
      single_result_with_document_series("rail-statistics"),
      document_series: document_series_registry
    )

    output = presenter.present
    assert_equal 1, output["results"][0]["document_series"].size
    assert_instance_of Hash, output["results"][0]["document_series"][0]
    assert_equal "Rail statistics", output["results"][0]["document_series"][0]["title"]
    assert_equal "/government/organisations/department-for-transport/series/rail-statistics",
      output["results"][0]["document_series"][0]["link"]
    assert_equal "rail-statistics", output["results"][0]["document_series"][0]["slug"]
  end

  def test_expands_document_collection
    rail_statistics_document = Document.new(
      sample_field_definitions(%w(link title)),
      link: "/government/collections/rail-statistics",
      title: "Rail statistics"
    )
    document_collection_registry = stub("document collection registry")
    document_collection_registry.expects(:[])
      .with("rail-statistics")
      .returns(rail_statistics_document)

    presenter = ResultSetPresenter.new(
      single_result_with_document_collection("rail-statistics"),
      document_collections: document_collection_registry
    )

    output = presenter.present
    assert_equal 1, output["results"][0]["document_collections"].size
    assert_instance_of Hash, output["results"][0]["document_collections"][0]
    assert_equal "Rail statistics", output["results"][0]["document_collections"][0]["title"]
    assert_equal "/government/collections/rail-statistics",
      output["results"][0]["document_collections"][0]["link"]
    assert_equal "rail-statistics", output["results"][0]["document_collections"][0]["slug"]
  end

  def test_expands_organisations
    mod_document = Document.new(
      sample_field_definitions(%w(link title)),
      link: "/government/organisations/ministry-of-defence",
      title: "Ministry of Defence (MoD)"
    )
    organisation_registry = stub("organisation registry")
    organisation_registry.expects(:[])
      .with("ministry-of-defence")
      .returns(mod_document)

    presenter = ResultSetPresenter.new(
      single_result_with_organisations("ministry-of-defence"),
      organisations: organisation_registry
    )

    output = presenter.present
    assert_equal 1, output["results"][0]["organisations"].size
    assert_instance_of Hash, output["results"][0]["organisations"][0]
    assert_equal "Ministry of Defence (MoD)", output["results"][0]["organisations"][0]["title"]
    assert_equal "/government/organisations/ministry-of-defence", output["results"][0]["organisations"][0]["link"]
    assert_equal "ministry-of-defence", output["results"][0]["organisations"][0]["slug"]
  end

  def test_expands_topics
    housing_document = Document.new(
      sample_field_definitions(%w(link title)),
      link: "/government/topics/housing",
      title: "Housing"
    )
    topic_registry = stub("topic registry")
    topic_registry.expects(:[])
      .with("housing")
      .returns(housing_document)

    presenter = ResultSetPresenter.new(
      single_result_with_topics("housing"),
      topics: topic_registry
    )

    output = presenter.present
    assert_equal 1, output["results"][0]["topics"].size
    assert_instance_of Hash, output["results"][0]["topics"][0]
    assert_equal "Housing", output["results"][0]["topics"][0]["title"]
    assert_equal "/government/topics/housing", output["results"][0]["topics"][0]["link"]
    assert_equal "housing", output["results"][0]["topics"][0]["slug"]
  end

  def test_expands_world_locations
    angola_world_location = Document.new(
      sample_field_definitions(%w(link title)),
      link: "/government/world/angola",
      title: "Angola"
    )
    world_location_registry = stub("world location registry")
    world_location_registry.expects(:[])
      .with("angola")
      .returns(angola_world_location)

    presenter = ResultSetPresenter.new(
      single_result_with_world_locations("angola"),
      world_locations: world_location_registry
    )

    output = presenter.present
    assert_equal 1, output["results"][0]["world_locations"].size
    assert_instance_of Hash, output["results"][0]["world_locations"][0]
    assert_equal "Angola", output["results"][0]["world_locations"][0]["title"]
    assert_equal "/government/world/angola", output["results"][0]["world_locations"][0]["link"]
    assert_equal "angola", output["results"][0]["world_locations"][0]["slug"]
  end

  def test_expands_sectors
    oil_gas_sector_fields = {
      "link" => "/topic/oil-and-gas/licensing",
      "title" => "Licensing",
      "slug" => "oil-and-gas/licensing",
    }
    specialist_sector_registry = stub("sector registry")
    specialist_sector_registry.expects(:[])
      .with("oil-and-gas/licensing")
      .returns(oil_gas_sector_fields)

    presenter = ResultSetPresenter.new(
      single_result_with_sectors("oil-and-gas/licensing"),
      specialist_sectors: specialist_sector_registry,
    )

    output = presenter.present
    assert_equal 1, output["results"][0]["specialist_sectors"].size
    assert_instance_of Hash, output["results"][0]["specialist_sectors"][0]
    assert_equal "Licensing", output["results"][0]["specialist_sectors"][0]["title"]
    assert_equal "/topic/oil-and-gas/licensing", output["results"][0]["specialist_sectors"][0]["link"]
    assert_equal "oil-and-gas/licensing", output["results"][0]["specialist_sectors"][0]["slug"]
  end

  def test_expands_people
    people_document = Document.new(
      sample_field_definitions(%w(link title)),
      link: "/government/people/example-people",
      title: "Example People"
    )
    people_registry = stub("people registry")
    people_registry.expects(:[])
      .with("example-people")
      .returns(people_document)

    presenter = ResultSetPresenter.new(
      single_result_with_people("example-people"),
      people: people_registry
    )

    output = presenter.present
    assert_equal 1, output["results"][0]["people"].size
    assert_instance_of Hash, output["results"][0]["people"][0]
    assert_equal "Example People", output["results"][0]["people"][0]["title"]
    assert_equal "/government/people/example-people", output["results"][0]["people"][0]["link"]
    assert_equal "example-people", output["results"][0]["people"][0]["slug"]
  end

  def test_unknown_organisations_just_have_slug
    organisation_registry = stub("organisation registry")
    organisation_registry.expects(:[])
      .returns(nil)

    presenter = ResultSetPresenter.new(
      single_result_with_organisations("ministry-of-silly-walks"),
      organisations: organisation_registry
    )

    output = presenter.present
    assert_equal 1, output["results"][0]["organisations"].size
    assert_instance_of Hash, output["results"][0]["organisations"][0]
    refute_includes output["results"][0]["organisations"][0], "title"
    refute_includes output["results"][0]["organisations"][0], "link"
    assert_equal "ministry-of-silly-walks", output["results"][0]["organisations"][0]["slug"]
  end

  def test_organisations_not_modified_if_no_registry_available
    presenter = ResultSetPresenter.new(
      single_result_with_organisations("ministry-of-silly-walks"),
      organisations: nil
    )

    output = presenter.present
    assert_equal 1, output["results"][0]["organisations"].size
    assert_equal "ministry-of-silly-walks", output["results"][0]["organisations"][0]
  end

  private

  def result_set
    documents = [
      {
        "link" => "/foo",
        "title" => "Foo",
        "description" => "Full of foo.",
        "format" => "edition"
      }
    ].map { |h| Document.new(sample_field_definitions(FIELDS), h) }

    stub("result set", results: documents, total: 1)
  end

  def single_result_with_format(format)
    stub(results: [Document.new(sample_field_definitions(FIELDS), :format => format)], total: 1)
  end

  def single_result_with_document_series(*document_series_slugs)
    document_hash = {
        "link" => "/foo",
        "title" => "Foo",
        "description" => "Full of foo.",
        "format" => "edition",
        "document_series" => document_series_slugs
      }

    stub(results: [Document.new(sample_field_definitions(FIELDS), document_hash)], total: 1)
  end

  def single_result_with_document_collection(*document_collection_slugs)
    document_hash = {
        "link" => "/foo",
        "title" => "Foo",
        "description" => "Full of foo.",
        "format" => "edition",
        "document_collections" => document_collection_slugs
      }

    stub(results: [Document.new(sample_field_definitions(FIELDS), document_hash)], total: 1)
  end

  def single_result_with_organisations(*organisation_slugs)
    document_hash = {
        "link" => "/foo",
        "title" => "Foo",
        "description" => "Full of foo.",
        "format" => "edition",
        "organisations" => organisation_slugs
      }

    stub(results: [Document.new(sample_field_definitions(FIELDS), document_hash)], total: 1)
  end

  def single_result_with_topics(*topic_slugs)
    document_hash = {
      "link" => "/foo",
      "title" => "Foo",
      "description" => "Full of foo.",
      "format" => "edition",
      "topics" => topic_slugs
    }
    stub(results: [Document.new(sample_field_definitions(FIELDS), document_hash)], total: 1)
  end

  def single_result_with_world_locations(*world_location_slugs)
    document_hash = {
      "link" => "/foo",
      "title" => "Foo",
      "description" => "Full of foo.",
      "format" => "edition",
      "world_locations" => world_location_slugs
    }
    stub(results: [Document.new(sample_field_definitions(FIELDS), document_hash)], total: 1)
  end

  def single_result_with_sectors(*sector_slugs)
    document_hash = {
      "link" => "/foo",
      "title" => "Foo",
      "description" => "Full of foo.",
      "format" => "edition",
      "specialist_sectors" => sector_slugs,
    }
    stub(results: [Document.new(sample_field_definitions(FIELDS), document_hash)], total: 1)
  end

  def single_result_with_people(*people_slugs)
    document_hash = {
      "link" => "/foo",
      "title" => "Foo",
      "description" => "Full of foo.",
      "format" => "edition",
      "people" => people_slugs,
    }
    stub(results: [Document.new(sample_field_definitions(FIELDS), document_hash)], total: 1)
  end
end
