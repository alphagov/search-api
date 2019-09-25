require "spec_helper"

RSpec.describe FieldTypes do
  context "after loading standard types" do
    before do
      @types = described_class.new(File.expand_path("../../../config/schema", File.dirname(__FILE__)))
    end

    it "recognise the `identifier` type" do
      expect(@types.get("identifier").name).to eq("identifier")
    end

    it "know that the `identifier` type is single-valued" do
      expect(@types.get("identifier").multivalued).to be_falsey
    end

    it "know that the `identifiers` type is multi-valued" do
      expect(@types.get("identifiers").multivalued).to be_truthy
    end

    it "know that the `identifiers` type has a `text` filter type" do
      expect(@types.get("identifiers").filter_type).to eq("text")
    end

    it "know that the `identifiers` type does not have children" do
      expect(@types.get("identifiers").children).to be_nil
    end

    it "know that the `objects` type has named children" do
      expect(@types.get("objects").children).to eq("named")
    end

    it "know that the `opaque object` type has dynamic children" do
      expect(@types.get("opaque_object").children).to eq("dynamic")
    end

    it "raise an error for unknown types" do
      expect_raises_message(%{Unknown field type "unknown"}) do
        @types.get("unknown")
      end
    end
  end

  context "loading raises an exception if configuration is invalid" do
    before do
      @types = described_class.new("/config/path")
    end

    it "fail if a field type has no es config property" do
      allow_any_instance_of(described_class).to receive(:load_json).and_return({ "identifier" => {} })
      expect_raises_message(%{Missing "es_config" in field type "identifier" in "/config/path/field_types.json"}) do
        @types.get("identifier")
      end
    end

    it "fail if a field type has an invalid `filter type` property" do
      allow_any_instance_of(described_class).to receive(:load_json).and_return(
        { "identifier" => { "es_config" => {}, "filter_type" => "bad value" } },
      )
      expect_raises_message(%{Invalid value for "filter_type" ("bad value") in field type "identifier" in "/config/path/field_types.json"}) do
        @types.get("identifier")
      end
    end

    it "fail if a field type has an invalid `children` property" do
      allow_any_instance_of(described_class).to receive(:load_json).and_return(
        { "identifier" => { "es_config" => {}, "children" => "bad value" } },
      )
      expect_raises_message(%{Invalid value for "children" ("bad value") in field type "identifier" in "/config/path/field_types.json"}) do
        @types.get("identifier")
      end
    end

    it "fail if a field type has an unknown property" do
      allow_any_instance_of(described_class).to receive(:load_json).and_return(
        { "identifier" => { "es_config" => {}, "foo" => true } },
      )
      expect_raises_message(%{Unknown keys (foo) in field type "identifier" in "/config/path/field_types.json"}) do
        @types.get("identifier")
      end
    end
  end

  def expect_raises_message(message)
    expect { yield }.to raise_error(message)
  end
end
