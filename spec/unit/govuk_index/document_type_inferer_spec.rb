require 'spec_helper'

RSpec.describe 'GovukIndex::DocumentTypeInfererTest' do
  it "infer_payload_document_type" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "help_page"
    }

    document_type_inferer = GovukIndex::DocumentTypeInferer.new(payload)

    assert_equal "edition", document_type_inferer.type
  end

  it "should_raise_not_found_error" do
    payload = { "document_type" => "gone" }

    GovukIndex::DocumentTypeInferer.any_instance.stubs(:existing_document).returns(nil)

    assert_raises(GovukIndex::NotFoundError) do
      GovukIndex::DocumentTypeInferer.new(payload).type
    end
  end

  it "should_raise_unknown_document_type_error" do
    payload = { "document_type" => "unknown" }

    GovukIndex::DocumentTypeInferer.any_instance.stubs(:elasticsearch_document_type).returns(nil)

    assert_raises(GovukIndex::UnknownDocumentTypeError) do
      GovukIndex::DocumentTypeInferer.new(payload).type
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

    GovukIndex::DocumentTypeInferer.any_instance.stubs(:existing_document).returns(existing_document)

    document_type_inferer = GovukIndex::DocumentTypeInferer.new(payload)

    assert_equal existing_document["_type"], document_type_inferer.type
  end
end
