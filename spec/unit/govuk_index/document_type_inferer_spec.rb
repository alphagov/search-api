require 'spec_helper'

RSpec.describe GovukIndex::DocumentTypeInferer do
  it "infer_payload_document_type" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "help_page"
    }

    document_type_inferer = described_class.new(payload)

    assert_equal "edition", document_type_inferer.type
  end

  it "should_raise_not_found_error" do
    payload = { "document_type" => "gone" }

    allow_any_instance_of(described_class).to receive(:existing_document).and_return(nil)

    assert_raises(GovukIndex::NotFoundError) do
      described_class.new(payload).type
    end
  end

  it "should_raise_unknown_document_type_error" do
    payload = { "document_type" => "unknown" }

    allow_any_instance_of(described_class).to receive(:elasticsearch_document_type).and_return(nil)

    assert_raises(GovukIndex::UnknownDocumentTypeError) do
      described_class.new(payload).type
    end
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

    assert_equal existing_document["_type"], document_type_inferer.type
  end
end
