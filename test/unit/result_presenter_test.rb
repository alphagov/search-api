require "test_helper"
require "search/presenters/result_presenter"

class ResultPresenterTest < MiniTest::Unit::TestCase
  def test_conversion_values_to_single_objects
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'format' => ['a-string'] }
    }

    result = Search::ResultPresenter.new(document, nil, sample_schema, Search::SearchParameters.new(return_fields: %w[format])).present

    assert_equal "a-string", result["format"]
  end

  def test_conversion_values_to_labelled_objects
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'railway_type' => ['heavy-rail', 'light-rail'] }
    }

    result = Search::ResultPresenter.new(document, nil, sample_schema, Search::SearchParameters.new(return_fields: %w[railway_type])).present

    assert_equal [{ "label" => "Heavy rail", "value" => "heavy-rail" },
                  { "label" => "Light rail", "value" => "light-rail" }], result["railway_type"]
  end
end
