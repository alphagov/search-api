require 'spec_helper'

RSpec.describe GovukIndex::DocumentTypeInferer do
  it "infer_payload_document_type" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "help_page"
    }

    document_type_inferer = described_class.new(payload)

    expect(document_type_inferer.type).to eq("edition")
  end

  it "should_raise_not_found_error" do
    payload = { "document_type" => "gone" }

    allow_any_instance_of(described_class).to receive(:existing_document).and_return(nil)

    expect {
      described_class.new(payload).type
    }.to raise_error(GovukIndex::NotFoundError)
  end

  it "infer_existing_document_type" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "redirect"
    }

    existing_document = {
      "_type" => "cheddar",
      "_id" => "/cheese"
    }

    allow_any_instance_of(described_class).to receive(:existing_document).and_return(existing_document)

    document_type_inferer = described_class.new(payload)

    expect(existing_document["_type"]).to eq(document_type_inferer.type)
  end
end
