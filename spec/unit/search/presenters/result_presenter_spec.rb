require "spec_helper"

RSpec.describe Search::ResultPresenter do
  it "conversion values to single objects" do
    document = {
      "_type" => "generic-document",
      "_index" => "govuk_test",
      "_source" => { "document_type" => "raib_report", "format" => ["a-string"] }
    }

    result = described_class.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[format])).present

    expect(result["format"]).to eq("a-string")
  end

  it "conversion values to labelled objects" do
    document = {
      "_type" => "generic-document",
      "_index" => "govuk_test",
      "_source" => { "document_type" => "raib_report", "railway_type" => ["heavy-rail", "light-rail"] }
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
