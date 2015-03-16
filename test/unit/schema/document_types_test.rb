require "test_helper"
require "schema/document_types"

class DocumentTypesTest < ShouldaUnitTestCase
  def assert_raises_message(message)
    exc = assert_raises(RuntimeError) { yield }
    assert_equal message, exc.message
  end

  def schema_dir
    File.expand_path('../../../config/schema', File.dirname(__FILE__))
  end

  def cma_case_allowed_values
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
    setup do
      field_definitions = FieldDefinitionParser.new(schema_dir).parse
      @types = DocumentTypesParser.new(schema_dir, field_definitions).parse
      @identifier_es_config = {"type"=>"string", "index"=>"not_analyzed", "include_in_all"=>false}
    end

    should "recognise the `manual_section` type" do
      assert_equal "manual_section", @types["manual_section"].name
    end

    should "know that the `manual_section` type has a `manual` field" do
      manual_field = @types["manual_section"].fields["manual"]
      refute manual_field.nil?
      assert_equal "manual", manual_field.name
    end

    should "know that the `manual_section` type inherits the `link` field from the base type" do
      link_field = @types["manual_section"].fields["link"]
      refute link_field.nil?
      assert_equal "link", link_field.name
      assert_equal false, link_field.type.multivalued
      assert_equal "identifier", link_field.type.name
    end

    should "produce appropriate elasticsearch configuration for the `manual_section` type" do
      es_config = @types["manual_section"].es_config
      assert_equal(
        hash_including({
          "manual" => @identifier_es_config,
          "link" => @identifier_es_config,
        }),
        es_config
      )
    end

    should "not specify allowed_values for the `organisations` field" do
      assert_nil @types["manual_section"].fields["organisations"].allowed_values
    end

    should "include allowed_values in the cma_case `case_state` field" do
      assert_equal(
        cma_case_allowed_values,
        @types["cma_case"].fields["case_state"].allowed_values
      )
    end

    should "allowed_values on a field should also be available from the document type" do
      assert_equal(
        @types["cma_case"].fields["case_state"].allowed_values,
        @types["cma_case"].allowed_values["case_state"]
      )
    end

  end

  context "when configuration is invalid" do
    setup do
      @definitions = FieldDefinitionParser.new(schema_dir).parse
      @parser = DocumentTypeParser.new("/config/path/doc_type.json", nil, @definitions)
    end

    should "fail if document type doesn't specify `fields`" do
      DocumentTypeParser.any_instance.stubs(:load_json).returns({})
      assert_raises_message(%{Missing "fields", in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end

    should "fail if document type specifies unknown entries in `fields`" do
      DocumentTypeParser.any_instance.stubs(:load_json).returns({
        "fields" => ["unknown_field"],
      })
      assert_raises_message(%{Undefined field \"unknown_field\", in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end

    should "fail if document type has an unknown property" do
      DocumentTypeParser.any_instance.stubs(:load_json).returns({
        "fields" => [],
        "unknown" => [],
      })
      assert_raises_message(%{Unknown keys (unknown), in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end

    should "fail if allowed values are specified in base type" do
      DocumentTypeParser.any_instance.stubs(:load_json).returns({
        "fields" => ["case_state"],
        "allowed_values" => {
          "case_state" => cma_case_allowed_values,
        },
      })
      base_type = @parser.parse

      subtype_parser = DocumentTypeParser.new("/config/path/subtype.json", base_type, @definitions)
      DocumentTypeParser.any_instance.stubs(:load_json).returns({"fields" => []})

      assert_raises_message(%{Specifying `allowed_values` in base document type is not supported, in document type definition in "/config/path/subtype.json"}) { subtype_parser.parse }
    end

    should "fail if allowed_values are set for fields which aren't known" do
      DocumentTypeParser.any_instance.stubs(:load_json).returns({
        "fields" => ["case_state"],
        "allowed_values" => {
          "unknown_field" => cma_case_allowed_values,
        },
      })

      assert_raises_message(%{Field "unknown_field" set in "allowed_values", but not in "fields", in document type definition in "/config/path/doc_type.json"}) { @parser.parse }
    end
  end
end
