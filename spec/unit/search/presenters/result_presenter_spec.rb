require 'spec_helper'

RSpec.describe 'ResultPresenterTest' do
  it "conversion_values_to_single_objects" do
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'format' => ['a-string'] }
    }

    result = Search::ResultPresenter.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[format])).present

    assert_equal "a-string", result["format"]
  end

  it "conversion_values_to_labelled_objects" do
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'railway_type' => ['heavy-rail', 'light-rail'] }
    }

    result = Search::ResultPresenter.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[railway_type])).present

    assert_equal [{ "label" => "Heavy rail", "value" => "heavy-rail" },
                  { "label" => "Light rail", "value" => "light-rail" }], result["railway_type"]
  end
end
