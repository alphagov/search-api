require "test_helper"
require "document"
require "result_set_presenter"
require "multi_json"

class ResultSetPresenterTest < MiniTest::Unit::TestCase

  FIELDS = %w(link title description format organisations)

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
    stub(results: [Document.new(FIELDS, :format => format)])
  end

  def single_result_with_organisations(*organisation_slugs)
    document_hash = {
        "link" => "/foo",
        "title" => "Foo",
        "description" => "Full of foo.",
        "format" => "edition",
        "organisations" => organisation_slugs
      }

    stub(results: [Document.new(FIELDS, document_hash)])
  end

  def output_for(presenter)
    MultiJson.decode(presenter.present)
  end

  def test_generates_json_from_documents
    presenter = ResultSetPresenter.new(result_set)
    output = output_for(presenter)
    assert_equal 1, output.length
    # Check all the fields from the document are present
    assert_equal [], %w(link title description format) - output[0].keys
  end

  def test_presented_json_includes_presentation_format
    presenter = ResultSetPresenter.new(result_set)
    output = output_for(presenter)
    assert_equal "edition", output[0]["presentation_format"]
  end

  def test_presented_json_includes_humanized_format
    presenter = ResultSetPresenter.new(result_set)
    output = output_for(presenter)
    assert_equal "Editions", output[0]["humanized_format"]
  end

  def test_should_use_answer_as_presentation_format_for_planner
    result_set = single_result_with_format "planner"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "answer", output[0]["presentation_format"]
  end

  def test_should_use_answer_as_presentation_format_for_smart_answer
    result_set = single_result_with_format "smart_answer"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "answer", output[0]["presentation_format"]
  end

  def test_should_use_answer_as_presentation_format_for_licence_finder
    result_set = single_result_with_format "licence_finder"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "answer", output[0]["presentation_format"]
  end

  def test_should_use_guide_as_presentation_format_for_guide
    result_set = single_result_with_format "guide"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "guide", output[0]["presentation_format"]
  end

  def test_should_use_humanized_format
    result_set = single_result_with_format "place"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "Services", output[0]["humanized_format"]
  end

  def test_uses_presentation_format_to_find_alternative_format_name
    presenter = ResultSetPresenter.new(single_result_with_format("foo"))
    presenter.stubs(:presentation_format).returns("place")

    assert_equal "Services", output_for(presenter)[0]["humanized_format"]
  end

  def test_generates_humanized_format_if_not_present
    result_set = single_result_with_format "ocean_map"
    output = output_for(ResultSetPresenter.new(result_set))
    assert_equal "Ocean maps", output[0]["humanized_format"]
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
    assert_equal 1, output[0]["organisations"].size
    assert_instance_of Hash, output[0]["organisations"][0]
    assert_equal "Ministry of Defence (MoD)", output[0]["organisations"][0]["title"]
    assert_equal "/government/organisations/ministry-of-defence", output[0]["organisations"][0]["link"]
    assert_equal "ministry-of-defence", output[0]["organisations"][0]["slug"]
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
    assert_equal 1, output[0]["organisations"].size
    assert_instance_of Hash, output[0]["organisations"][0]
    refute_includes output[0]["organisations"][0], "title"
    refute_includes output[0]["organisations"][0], "link"
    assert_equal "ministry-of-silly-walks", output[0]["organisations"][0]["slug"]
  end

  def test_organisations_just_have_slug_if_no_registry_available
    presenter = ResultSetPresenter.new(
      single_result_with_organisations("ministry-of-silly-walks"),
      organisation_registry: nil
    )

    output = output_for(presenter)
    assert_equal 1, output[0]["organisations"].size
    assert_equal "ministry-of-silly-walks", output[0]["organisations"][0]["slug"]
  end
end
