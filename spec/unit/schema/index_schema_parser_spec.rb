require 'spec_helper'

RSpec.describe IndexSchemaParser do
  def expect_raises_message(message)
    expect { yield }.to raise_error(message)
  end

  def schema_dir
    File.expand_path('../../../config/schema', File.dirname(__FILE__))
  end

  context "after loading standard index schemas" do
    before do
      field_definitions = FieldDefinitionParser.new(schema_dir).parse
      elasticsearch_types = ElasticsearchTypesParser.new(schema_dir, field_definitions).parse
      @index_schemas = described_class.parse_all(schema_dir, field_definitions, elasticsearch_types)
      @identifier_es_config = { "type" => "keyword", "index" => true }
    end

    it "have a schema for the govuk index" do
      expect(@index_schemas["govuk"].name).to eq("govuk")
    end

    it "include configuration for the `manual section` type in the `govuk` index" do
      es_mappings = @index_schemas["govuk"].es_mappings
      expect(es_mappings.keys).to include("generic-document")
      expect(
        hash_including({
          "manual" => @identifier_es_config,
          "link" => @identifier_es_config,
        })
      ).to eq(
        es_mappings["generic-document"]["properties"]
      )
    end
  end

  context "when configuration is invalid" do
    before do
      field_definitions = FieldDefinitionParser.new(schema_dir).parse
      elasticsearch_types = ElasticsearchTypesParser.new(schema_dir, field_definitions).parse
      @parser = described_class.new("index", "index.json", field_definitions, elasticsearch_types)
    end

    it "fail if index schema specifies an unknown document_type" do
      allow_any_instance_of(described_class).to receive(:load_json).and_return({
        "elasticsearch_types" => ["unknown_doc_type"],
      })
      expect_raises_message(%{Unknown document type "unknown_doc_type", in index definition in "index.json"}) { @parser.parse }
    end

    it "fail if index schema doesn't specify `elasticsearch types`" do
      allow_any_instance_of(described_class).to receive(:load_json).and_return({})
      expect_raises_message(%{Missing "elasticsearch_types", in index definition in "index.json"}) { @parser.parse }
    end

    it "fail if index schema includes unknown keys" do
      allow_any_instance_of(described_class).to receive(:load_json).and_return({
        "elasticsearch_types" => [],
        "foo" => "bar",
      })
      expect_raises_message(%{Unknown keys (foo), in index definition in "index.json"}) { @parser.parse }
    end
  end
end
