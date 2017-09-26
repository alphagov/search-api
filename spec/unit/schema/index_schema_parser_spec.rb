require 'spec_helper'

RSpec.describe IndexSchemaParser, tags: ['shoulda'] do
  def assert_raises_message(message)
    exc = assert_raises(RuntimeError) { yield }
    assert_equal message, exc.message
  end

  def schema_dir
    File.expand_path('../../../config/schema', File.dirname(__FILE__))
  end

  context "after loading standard index schemas" do
    before do
      field_definitions = FieldDefinitionParser.new(schema_dir).parse
      elasticsearch_types = ElasticsearchTypesParser.new(schema_dir, field_definitions).parse
      @index_schemas = described_class.parse_all(schema_dir, elasticsearch_types)
      @identifier_es_config = { "type" => "string", "index" => "not_analyzed", "include_in_all" => false }
    end

    it "have a schema for the mainstream index" do
      assert_equal "mainstream", @index_schemas["mainstream"].name
    end

    it "include configuration for the `manual_section` type in the `mainstream` index" do
      es_mappings = @index_schemas["mainstream"].es_mappings
      assert es_mappings.keys.include?("manual_section")
      assert_equal(
        hash_including({
          "manual" => @identifier_es_config,
          "link" => @identifier_es_config,
        }),
        es_mappings["manual_section"]["properties"]
      )
    end
  end

  context "when configuration is invalid" do
    before do
      field_definitions = FieldDefinitionParser.new(schema_dir).parse
      elasticsearch_types = ElasticsearchTypesParser.new(schema_dir, field_definitions).parse
      @parser = described_class.new("index", "index.json", elasticsearch_types)
    end

    it "fail if index schema specifies an unknown document type" do
      described_class.any_instance.stub(:load_json).and_return({
        "elasticsearch_types" => ["unknown_doc_type"],
      })
      assert_raises_message(%{Unknown document type "unknown_doc_type", in index definition in "index.json"}) { @parser.parse }
    end

    it "fail if index schema doesn't specify `elasticsearch_types`" do
      described_class.any_instance.stub(:load_json).and_return({})
      assert_raises_message(%{Missing "elasticsearch_types", in index definition in "index.json"}) { @parser.parse }
    end

    it "fail if index schema includes unknown keys" do
      described_class.any_instance.stub(:load_json).and_return({
        "elasticsearch_types" => [],
        "foo" => "bar",
      })
      assert_raises_message(%{Unknown keys (foo), in index definition in "index.json"}) { @parser.parse }
    end
  end
end
