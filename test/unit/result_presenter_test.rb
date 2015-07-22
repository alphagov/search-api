require "test_helper"
require "result_presenter"

class ResultPresenterTest < MiniTest::Unit::TestCase
  def test_conversion_values_to_single_objects
    document = {
      "format" => ['a-string'],
      _metadata: { '_type' => 'raib_report', '_index' => 'mainstream_test' }
    }

    result = ResultPresenter.new(document, nil, sample_schema).present

    assert_equal "a-string", result["format"]
  end

  def test_conversion_values_to_labelled_objects
    document =  {
      "railway_type" => ['heavy-rail', 'light-rail'],
      _metadata: { '_type' => 'raib_report', '_index' => 'mainstream_test' }
    }

    result = ResultPresenter.new(document, nil, sample_schema).present

    assert_equal [{"label"=>"Heavy rail", "value"=>"heavy-rail"},
        {"label"=>"Light rail", "value"=>"light-rail"}], result["railway_type"]
  end
end
