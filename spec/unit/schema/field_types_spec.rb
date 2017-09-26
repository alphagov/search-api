require 'spec_helper'

RSpec.describe FieldTypes, tags: ['shoulda'] do
  context "after loading standard types" do
    before do
      @types = described_class.new(File.expand_path('../../../config/schema', File.dirname(__FILE__)))
    end

    it "recognise the `identifier` type" do
      assert_equal "identifier", @types.get("identifier").name
    end

    it "know that the `identifier` type is single-valued" do
      refute @types.get("identifier").multivalued
    end

    it "know that the `identifiers` type is multi-valued" do
      assert @types.get("identifiers").multivalued
    end

    it "know that the `identifiers` type has a `text` filter type" do
      assert_equal "text", @types.get("identifiers").filter_type
    end

    it "know that the `identifiers` type does not have children" do
      assert_nil @types.get("identifiers").children
    end

    it "know that the `objects` type has named children" do
      assert_equal "named", @types.get("objects").children
    end

    it "know that the `opaque_object` type has dynamic children" do
      assert_equal "dynamic", @types.get("opaque_object").children
    end

    it "raise an error for unknown types" do
      exc = assert_raises(RuntimeError) do
        @types.get("unknown")
      end
      assert_equal %{Unknown field type "unknown"}, exc.message
    end
  end

  context "loading raises an exception if configuration is invalid" do
    before do
      @types = described_class.new("/config/path")
    end

    it "fail if a field type has no es_config property" do
      described_class.any_instance.stub(:load_json).and_return({ "identifier" => {} })
      exc = assert_raises(RuntimeError) do
        @types.get("identifier")
      end
      assert_equal %{Missing "es_config" in field type "identifier" in "/config/path/field_types.json"}, exc.message
    end

    it "fail if a field type has an invalid `filter_type` property" do
      described_class.any_instance.stub(:load_json).and_return(
        { "identifier" => { "es_config" => {}, "filter_type" => "bad value" } }
      )
      exc = assert_raises(RuntimeError) do
        @types.get("identifier")
      end
      assert_equal %{Invalid value for "filter_type" ("bad value") in field type "identifier" in "/config/path/field_types.json"}, exc.message
    end

    it "fail if a field type has an invalid `children` property" do
      described_class.any_instance.stub(:load_json).and_return(
        { "identifier" => { "es_config" => {}, "children" => "bad value" } }
      )
      exc = assert_raises(RuntimeError) do
        @types.get("identifier")
      end
      assert_equal %{Invalid value for "children" ("bad value") in field type "identifier" in "/config/path/field_types.json"}, exc.message
    end

    it "fail if a field type has an unknown property" do
      described_class.any_instance.stub(:load_json).and_return(
        { "identifier" => { "es_config" => {}, "foo" => true } }
      )
      exc = assert_raises(RuntimeError) do
        @types.get("identifier")
      end
      assert_equal %{Unknown keys (foo) in field type "identifier" in "/config/path/field_types.json"}, exc.message
    end
  end
end
