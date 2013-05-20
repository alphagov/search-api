require "test_helper"
require "document"
require "result_set_presenter"

class ResultSetPresenterTest < MiniTest::Unit::TestCase

  FIELDS = %w(link title description format)

  def documents
    [
      {
        "link" => "/foo",
        "title" => "Foo",
        "description" => "Full of foo.",
        "format" => "edition"
      }
    ].map { |h| Document.new(FIELDS, h) }
  end

  def test_generates_json_from_documents
    presenter = ResultSetPresenter.new(documents)
    json = presenter.present
    output = MultiJson.decode(json)
    assert_equal 1, output.length
    assert_equal [], FIELDS - output[0].keys
  end

  def test_presented_json_includes_presentation_format
    presenter = ResultSetPresenter.new(documents)
    json = presenter.present
    output = MultiJson.decode(json)
    assert_equal "edition", output[0]["presentation_format"]
  end

  def test_presented_json_includes_humanized_format
    presenter = ResultSetPresenter.new(documents)
    json = presenter.present
    output = MultiJson.decode(json)
    assert_equal "Editions", output[0]["humanized_format"]
  end
end
