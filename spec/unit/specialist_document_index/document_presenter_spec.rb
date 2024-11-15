require "spec_helper"

RSpec.describe SpecialistDocumentIndex::DocumentPresenter do
  it "identifies the document" do
    payload = { payload_version: 1, base_path: "/path", document_type: "specialist_document" }

    expected_identifier = {
      _type: "generic-document",
      _id: payload["base_path"],
      version: 1,
      version_type: "external",
    }

    presenter = described_class.new(payload)

    expect(expected_identifier).to eq(presenter.identifier)
  end

  it "merges the format into the document" do
    payload = { payload_version: 1, base_path: "/path", document_type: "specialist_document" }

    expected_document = {
      _type: "generic-document",
      _id: payload["base_path"],
      version: 1,
      version_type: "external",
    }

    presenter = described_class.new(payload)

    expect(expected_identifier).to eq(presenter.identifier)
  end
end
