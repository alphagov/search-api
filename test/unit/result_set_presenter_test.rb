require "test_helper"
require "document"
require "result_set_presenter"
require "multi_json"

class ResultSetPresenterTest < MiniTest::Unit::TestCase

  FIELDS = %w(link title description format)

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

  def output_for(presenter)
    MultiJson.decode(presenter.present)
  end

  def test_generates_json_from_documents
    presenter = ResultSetPresenter.new(result_set)
    output = output_for(presenter)
    assert_equal 1, output.length
    assert_equal [], FIELDS - output[0].keys
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
end
