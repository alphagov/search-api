require 'spec_helper'

RSpec.describe 'ElasticsearchTypesTest', tags: ['shoulda'] do
  def assert_raises_message(message)
    exc = assert_raises(RuntimeError) { yield }
    assert_equal message, exc.message
  end

  def schema_dir
    File.expand_path('../../../config/schema', File.dirname(__FILE__))
  end

  def cma_case_expanded_search_result_fields
    [
      {
        "label" => "Open",
        "value" => "open",
      },
      {
        "label" => "Closed",
        "value" => "closed",
      },
    ]
  end

  context "after loading standard types" do
    before do
      field_definitions = FieldDefinitionParser.new(schema_dir).parse
      @types = ElasticsearchTypesParser.new(schema_dir, field_definitions).parse
      @identifier_es_config = { "type" => "string", "index" => "not_analyzed", "include_in_all" => false }
    end

    it "recognise the `manual_section` type" do
      assert_equal "manual_section", @types["manual_section"].name
    end

    it "know that the `manual_section` type has a `manual` field" do
      manual_field = @types["manual_section"].fields["manual"]
      refute manual_field.nil?
      assert_equal "manual", manual_field.name
    end

    it "know that the `manual_section` type inherits the `link` field from the base type" do
      link_field = @types["manual_section"].fields["link"]
      refute link_field.nil?
      assert_equal "link", link_field.name
      assert_equal false, link_field.type.multivalued
      assert_equal "identifier", link_field.type.name
    end

    it "produce appropriate elasticsearch configuration for the `manual_section` type" do
      es_config = @types["manual_section"].es_config
      assert_equal(
        hash_including({
          "manual" => @identifier_es_config,
          "link" => @identifier_es_config,
        }),
        es_config
      )
    end

    it "not specify expanded_search_result_fields for the `organisations` field" do
      assert_nil @types["manual_section"].fields["organisations"].expanded_search_result_fields
    end

    it "include expanded_search_result_fields in the cma_case `case_state` field" do
      assert_equal(
        cma_case_expanded_search_result_fields,
        @types["cma_case"].fields["case_state"].expanded_search_result_fields
      )
    end

    it "expanded_search_result_fields on a field should also be available from the document type" do
      assert_equal(
        @types["cma_case"].fields["case_state"].expanded_search_result_fields,
        @types["cma_case"].expanded_search_result_fields["case_state"]
      )
    end
  end

  context "when configuration is invalid" do
    before do
      @definitions = FieldDefinitionParser.new(schema_dir).parse
      @parser = ElasticsearchTypeParser.new("/config/path/doc_type.json", nil, @definitions)
    end

    it "fail if document type doesn't specify `fields`" do
      ElasticsearchTypeParser.any_instance.stub(:load_json).and_return({})
      assert_raises_message(%{Missing "fields", in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end

    it "fail if document type specifies unknown entries in `fields`" do
      ElasticsearchTypeParser.any_instance.stub(:load_json).and_return({
        "fields" => ["unknown_field"],
      })
      assert_raises_message(%{Undefined field \"unknown_field\", in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end

    it "fail if document type has an unknown property" do
      ElasticsearchTypeParser.any_instance.stub(:load_json).and_return({
        "fields" => [],
        "unknown" => [],
      })
      assert_raises_message(%{Unknown keys (unknown), in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end

    it "fail if `expanded_search_result_fields` are specified in base type" do
      ElasticsearchTypeParser.any_instance.stub(:load_json).and_return({
        "fields" => ["case_state"],
        "expanded_search_result_fields" => {
          "case_state" => cma_case_expanded_search_result_fields,
        },
      })
      base_type = @parser.parse

      subtype_parser = ElasticsearchTypeParser.new("/config/path/subtype.json", base_type, @definitions)
      ElasticsearchTypeParser.any_instance.stub(:load_json).and_return({ "fields" => [] })

      assert_raises_message(%{Specifying `expanded_search_result_fields` in base document type is not supported, in document type definition in "/config/path/subtype.json"}) { subtype_parser.parse }
    end

    it "fail if expanded_search_result_fields are set for fields which aren't known" do
      ElasticsearchTypeParser.any_instance.stub(:load_json).and_return({
        "fields" => ["case_state"],
        "expanded_search_result_fields" => {
          "unknown_field" => cma_case_expanded_search_result_fields,
        },
      })

      assert_raises_message(%{Field "unknown_field" set in "expanded_search_result_fields", but not in "fields", in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end
  end
end
