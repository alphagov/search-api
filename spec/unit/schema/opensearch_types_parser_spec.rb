require "spec_helper"

RSpec.describe ElasticsearchTypesParser do
  def expect_raises_message(message, &block)
    expect(&block).to raise_error(message)
  end

  def schema_dir
    File.expand_path("../../../config/schema", File.dirname(__FILE__))
  end

  context "after loading standard types" do
    before do
      field_definitions = FieldDefinitionParser.new(schema_dir).parse
      @types = described_class.new(schema_dir, field_definitions).parse
      @identifier_es_config = { "type" => "keyword", "index" => true }
    end

    it "recognise the `manual section` type" do
      expect(@types["manual_section"].name).to eq("manual_section")
    end

    it "know that the `manual section` type has a `manual` field" do
      manual_field = @types["manual_section"].fields["manual"]
      expect(manual_field).not_to be_nil
      expect(manual_field.name).to eq("manual")
    end

    it "know that the `manual section` type inherits the `link` field from the base type" do
      link_field = @types["manual_section"].fields["link"]
      expect(link_field).not_to be_nil
      expect(link_field.name).to eq("link")
      expect(false).to eq(link_field.type.multivalued)
      expect(link_field.type.name).to eq("identifier")
    end

    it "produce appropriate elasticsearch configuration for the `manual section` type" do
      es_config = @types["manual_section"].es_config
      expect(es_config).to match(
        hash_including({
          "manual" => @identifier_es_config,
          "link" => @identifier_es_config,
        }),
      )
    end
  end

  context "when configuration is invalid" do
    before do
      @definitions = FieldDefinitionParser.new(schema_dir).parse
      @parser = ElasticsearchTypeParser.new("/config/path/doc_type.json", nil, @definitions)
    end

    it "fail if document_type doesn't specify `fields`" do
      allow_any_instance_of(ElasticsearchTypeParser).to receive(:load_json).and_return({})
      expect_raises_message(%(Missing "fields", in document type definition in "/config/path/doc_type.json")) { @parser.parse }
    end

    it "fail if document_type specifies unknown entries in `fields`" do
      allow_any_instance_of(ElasticsearchTypeParser).to receive(:load_json).and_return({
        "fields" => %w[unknown_field],
      })
      expect_raises_message(%(Undefined field \"unknown_field\", in document type definition in "/config/path/doc_type.json")) { @parser.parse }
    end

    it "fail if document_type has an unknown property" do
      allow_any_instance_of(ElasticsearchTypeParser).to receive(:load_json).and_return({
        "fields" => [],
        "unknown" => [],
      })
      expect_raises_message(%{Unknown keys (unknown), in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end
  end
end
