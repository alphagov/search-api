require "spec_helper"

RSpec.describe Search::ResultPresenter, "Temporary Link Fix" do
  it "appending a slash to the link field" do
    document = {
      "_type" => "generic-document",
      "_index" => "govuk_test",
      "_source" => { "document_type" => "raib_report", "link" => ["some/link"] }
    }

    result = described_class.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[link])).present

    expect(result["link"]).to eq("/some/link")
  end

  it "keep http links intact" do
    document = {
      "_type" => "generic-document",
      "_index" => "govuk_test",
      "_source" => { "document_type" => "raib_report", "link" => ["http://example.org/some-link"] }
    }

    result = described_class.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[link])).present

    expect(result["link"]).to eq("http://example.org/some-link")
  end

  it "keep correct links intact" do
    document = {
      "_type" => "generic-document",
      "_index" => "govuk_test",
      "_source" => { "document_type" => "raib_report", "link" => ["/some-link"] }
    }

    result = described_class.new(document, nil, sample_schema, Search::QueryParameters.new(return_fields: %w[link])).present

    expect(result["link"]).to eq("/some-link")
  end
end
