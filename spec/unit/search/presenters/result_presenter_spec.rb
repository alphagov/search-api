require "spec_helper"

RSpec.describe Search::ResultPresenter do
  it "conversion values to single objects" do
    document = {
      "_type" => "generic-document",
      "_index" => "govuk_test",
      "_source" => { "document_type" => "raib_report", "format" => %w[a-string] },
    }

    result = described_class.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[format]), result_rank: 1).present

    expect(result["format"]).to eq("a-string")
  end

  it "limits the number of parts to 10" do
    document = {
      "_type" => "generic-document",
      "_index" => "govuk_test",
      "_source" => { "document_type" => "edition", "parts" => ([{ a: "part" }] * 20) },
    }

    result = described_class.new(
      document,
      nil,
      sample_schema,
      Search::QueryParameters.new(return_fields: %w[parts]),
      result_rank: 1,
    ).present

    expect(result["parts"].count).to eq(10)
  end

  it "only displays parts for the top 3 results" do
    document = {
      "_type" => "generic-document",
      "_index" => "govuk_test",
      "_source" => { "document_type" => "edition", "parts" => [{ a: "part" }] },
    }

    (1..5).each do |rank|
      result = described_class.new(
        document,
        nil,
        sample_schema,
        Search::QueryParameters.new(return_fields: %w[parts]),
        result_rank: rank,
      ).present

      expect(result["parts"].count).to eq(rank <= 3 ? 1 : 0)
    end
  end
end
