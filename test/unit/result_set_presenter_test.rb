require "test_helper"
require "result_set_presenter"

class ResultSetPresenterTest < MiniTest::Unit::TestCase
  def test_converts_all_results
    presenter = ResultSetPresenter.new(
      ResultSet.new([ { title: "A title of a document" } ])
    )

    results = presenter.results

    assert_equal 1, results.size
    assert_equal "A title of a document", results.first[:title]
  end
end
