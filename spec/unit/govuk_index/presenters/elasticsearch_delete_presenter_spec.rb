require "spec_helper"

RSpec.describe GovukIndex::ElasticsearchDeletePresenter do
  it "generates an identifier for Elasticsearch" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "redirect",
      "payload_version" => 15,
    }

    existing_document = {
      "_source" => { "document_type" => "cheddar" },
      "_id" => "/cheese",
      "payload_version" => 8,
    }

    allow_any_instance_of(described_class).to receive(:existing_document).and_return(existing_document)

    expected_identifier = {
      _type: "generic-document",
      _id: "/cheese",
      version: 15,
      version_type: "external",
    }

    presenter = described_class.new(payload:)

    expect(expected_identifier).to eq(presenter.identifier)
  end

  it "raises an error if the existing document is not found" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "redirect",
      "payload_version" => 15,
    }

    allow_any_instance_of(described_class).to receive(:existing_document).and_return(nil)

    presenter = described_class.new(payload:)

    expect { presenter.type }.to raise_error(GovukIndex::NotFoundError)
  end
end
