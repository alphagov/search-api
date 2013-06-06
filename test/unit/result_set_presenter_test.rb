require "test_helper"
require "document"
require "result_set_presenter"
require "multi_json"

class ResultSetPresenterTest < MiniTest::Unit::TestCase

  FIELDS = %w(link title description format organisations topics document_series world_locations)

  def result_set
    documents = [
      {
        "link" => "/foo",
        "title" => "Foo",
        "description" => "Full of foo.",
        "format" => "edition"
      }
    ].map { |h| Document.new(FIELDS, h) }

    stub("result set", results: documents, total: 1)
  end

  def single_result_with_format(format)
    stub(results: [Document.new(FIELDS, :format => format)], total: 1)
  end

  def single_result_with_document_series(*document_series_slugs)
    document_hash = {
        "link" => "/foo",
        "title" => "Foo",
        "description" => "Full of foo.",
        "format" => "edition",
        "document_series" => document_series_slugs
      }

    stub(results: [Document.new(FIELDS, document_hash)], total: 1)
  end

  def single_result_with_organisations(*organisation_slugs)
    document_hash = {
        "link" => "/foo",
        "title" => "Foo",
        "description" => "Full of foo.",
        "format" => "edition",
        "organisations" => organisation_slugs
      }

    stub(results: [Document.new(FIELDS, document_hash)], total: 1)
  end

  def single_result_with_topics(*topic_slugs)
    document_hash = {
      "link" => "/foo",
      "title" => "Foo",
      "description" => "Full of foo.",
      "format" => "edition",
      "topics" => topic_slugs
    }
    stub(results: [Document.new(FIELDS, document_hash)], total: 1)
  end

  def single_result_with_world_locations(*world_location_slugs)
    document_hash = {
      "link" => "/foo",
      "title" => "Foo",
      "description" => "Full of foo.",
      "format" => "edition",
      "world_locations" => world_location_slugs
    }
    stub(results: [Document.new(FIELDS, document_hash)], total: 1)
  end

  def output_for(presenter)
    MultiJson.decode(presenter.present)
  end

  def test_generates_json_from_documents
    presenter = ResultSetPresenter.new(result_set)
    output = output_for(presenter)
    assert_equal 1, output["results"].length
    # Check all the fields from the document are present
    assert_equal [], %w(link title description format) - output["results"][0].keys
  end

  def test_presented_json_includes_presentation_format
    presenter = ResultSetPresenter.new(result_set)
    output = output_for(presenter)
    assert_equal "edition", output["results"][0]["presentation_format"]
  end

  def test_presented_json_includes_humanized_format
    presenter = ResultSetPresenter.new(result_set)
    output = output_for(presenter)
    assert_equal "Editions", output["results"][0]["humanized_format"]
  end

  def test_should_use_answer_as_presentation_format_for_planner
    result_set = single_result_with_format "planner"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "answer", output["results"][0]["presentation_format"]
  end

  def test_should_use_answer_as_presentation_format_for_smart_answer
    result_set = single_result_with_format "smart_answer"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "answer", output["results"][0]["presentation_format"]
  end

  def test_should_use_answer_as_presentation_format_for_licence_finder
    result_set = single_result_with_format "licence_finder"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "answer", output["results"][0]["presentation_format"]
  end

  def test_should_use_guide_as_presentation_format_for_guide
    result_set = single_result_with_format "guide"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "guide", output["results"][0]["presentation_format"]
  end

  def test_should_use_humanized_format
    result_set = single_result_with_format "place"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "Services", output["results"][0]["humanized_format"]
  end

  def test_uses_presentation_format_to_find_alternative_format_name
    presenter = ResultSetPresenter.new(single_result_with_format("foo"))
    presenter.stubs(:presentation_format).returns("place")

    assert_equal "Services", output_for(presenter)["results"][0]["humanized_format"]
  end

  def test_generates_humanized_format_if_not_present
    result_set = single_result_with_format "ocean_map"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "Ocean maps", output["results"][0]["humanized_format"]
  end

  def test_expands_document_series
    rail_statistics_document = Document.new(
      %w(link title),
      link: "/government/organisations/department-for-transport/series/rail-statistics",
      title: "Rail statistics"
    )
    document_series_registry = stub("document series registry")
    document_series_registry.expects(:[])
      .with("rail-statistics")
      .returns(rail_statistics_document)

    presenter = ResultSetPresenter.new(
      single_result_with_document_series("rail-statistics"),
      document_series_registry: document_series_registry
    )

    output = output_for(presenter)
    assert_equal 1, output["results"][0]["document_series"].size
    assert_instance_of Hash, output["results"][0]["document_series"][0]
    assert_equal "Rail statistics", output["results"][0]["document_series"][0]["title"]
    assert_equal "/government/organisations/department-for-transport/series/rail-statistics",
      output["results"][0]["document_series"][0]["link"]
    assert_equal "rail-statistics", output["results"][0]["document_series"][0]["slug"]
  end

  def test_expands_organisations
    mod_document = Document.new(
      %w(link title),
      link: "/government/organisations/ministry-of-defence",
      title: "Ministry of Defence (MoD)"
    )
    organisation_registry = stub("organisation registry")
    organisation_registry.expects(:[])
      .with("ministry-of-defence")
      .returns(mod_document)

    presenter = ResultSetPresenter.new(
      single_result_with_organisations("ministry-of-defence"),
      organisation_registry: organisation_registry
    )

    output = output_for(presenter)
    assert_equal 1, output["results"][0]["organisations"].size
    assert_instance_of Hash, output["results"][0]["organisations"][0]
    assert_equal "Ministry of Defence (MoD)", output["results"][0]["organisations"][0]["title"]
    assert_equal "/government/organisations/ministry-of-defence", output["results"][0]["organisations"][0]["link"]
    assert_equal "ministry-of-defence", output["results"][0]["organisations"][0]["slug"]
  end

  def test_expands_topics
    housing_document = Document.new(
      %w(link title),
      link: "/government/topics/housing",
      title: "Housing"
    )
    topic_registry = stub("topic registry")
    topic_registry.expects(:[])
      .with("housing")
      .returns(housing_document)

    presenter = ResultSetPresenter.new(
      single_result_with_topics("housing"),
      topic_registry: topic_registry
    )

    output = output_for(presenter)
    assert_equal 1, output["results"][0]["topics"].size
    assert_instance_of Hash, output["results"][0]["topics"][0]
    assert_equal "Housing", output["results"][0]["topics"][0]["title"]
    assert_equal "/government/topics/housing", output["results"][0]["topics"][0]["link"]
    assert_equal "housing", output["results"][0]["topics"][0]["slug"]
  end

  def test_expands_world_locations
    angola_world_location = Document.new(
      %w(link title),
      link: "/government/world/angola",
      title: "Angola"
    )
    world_location_registry = stub("world location registry")
    world_location_registry.expects(:[])
      .with("angola")
      .returns(angola_world_location)

    presenter = ResultSetPresenter.new(
      single_result_with_world_locations("angola"),
      world_location_registry: world_location_registry
    )

    output = output_for(presenter)
    assert_equal 1, output["results"][0]["world_locations"].size
    assert_instance_of Hash, output["results"][0]["world_locations"][0]
    assert_equal "Angola", output["results"][0]["world_locations"][0]["title"]
    assert_equal "/government/world/angola", output["results"][0]["world_locations"][0]["link"]
    assert_equal "angola", output["results"][0]["world_locations"][0]["slug"]
  end

  def test_unknown_organisations_just_have_slug
    organisation_registry = stub("organisation registry")
    organisation_registry.expects(:[])
      .returns(nil)

    presenter = ResultSetPresenter.new(
      single_result_with_organisations("ministry-of-silly-walks"),
      organisation_registry: organisation_registry
    )

    output = output_for(presenter)
    assert_equal 1, output["results"][0]["organisations"].size
    assert_instance_of Hash, output["results"][0]["organisations"][0]
    refute_includes output["results"][0]["organisations"][0], "title"
    refute_includes output["results"][0]["organisations"][0], "link"
    assert_equal "ministry-of-silly-walks", output["results"][0]["organisations"][0]["slug"]
  end

  def test_organisations_not_modified_if_no_registry_available
    presenter = ResultSetPresenter.new(
      single_result_with_organisations("ministry-of-silly-walks"),
      organisation_registry: nil
    )

    output = output_for(presenter)
    assert_equal 1, output["results"][0]["organisations"].size
    assert_equal "ministry-of-silly-walks", output["results"][0]["organisations"][0]
  end

  def test_includes_spelling_suggestions
    presenter = ResultSetPresenter.new(
      result_set,
      spelling_suggestions: ["spelling can be improved"]
    )

    output = output_for(presenter)
    expected = [
      "spelling can be improved"
    ]
    assert_equal expected, output["spelling_suggestions"]
  end

  def test_excludes_spelling_suggestions_when_not_supplied
    presenter = ResultSetPresenter.new(
      result_set,
      spelling_suggestions: nil # nil, not empty array
    )

    output = output_for(presenter)
    assert_equal ["total", "results"], output.keys
  end
end
