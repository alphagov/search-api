require 'spec_helper'

RSpec.describe Search::ResultPresenter do
  it "conversion_values_to_single_objects" do
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'format' => ['a-string'] }
    }

    result = described_class.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[format])).present

    expect("a-string").to eq(result["format"])
  end

  it "conversion_values_to_labelled_objects" do
    document = {
      '_type' => 'raib_report',
      '_index' => 'mainstream_test',
      'fields' => { 'railway_type' => ['heavy-rail', 'light-rail'] }
    }

    result = described_class.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[railway_type])).present

    expect(
      [
        { "label" => "Heavy rail", "value" => "heavy-rail" },
        { "label" => "Light rail", "value" => "light-rail" }
      ]
    ).to eq(result["railway_type"])
  end
end
