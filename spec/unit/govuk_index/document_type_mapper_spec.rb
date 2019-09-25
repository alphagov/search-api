require "spec_helper"

RSpec.describe GovukIndex::DocumentTypeMapper do
  it "infer payload document_type" do
    payload = {
      "base_path" => "/cheese",
      "document_type" => "help_page"
    }

    document_type_mapper = described_class.new(payload)

    expect(document_type_mapper.type).to eq("edition")
  end
end
