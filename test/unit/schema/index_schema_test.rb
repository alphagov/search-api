require "test_helper"
require "schema/index_schema"

class IndexSchemaTest < ShouldaUnitTestCase
  def assert_raises_message(message)
    exc = assert_raises(RuntimeError) { yield }
    assert_equal message, exc.message
  end

  context "after loading standard index schemas" do
    setup do
      @index_schemas = IndexSchemaParser.parse_all(File.expand_path('../../../config/schema', File.dirname(__FILE__)))
      @identifier_es_config = {"type"=>"string", "index"=>"not_analyzed", "include_in_all"=>false}
    end

    should "have a schema for the mainstream index" do
      assert_equal "mainstream", @index_schemas["mainstream"].name
    end

    should "include configuration for the `manual_section` type in the `mainstream` index" do
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
    setup do
      @document_types = DocumentTypesParser.new(File.expand_path('../../../config/schema', File.dirname(__FILE__))).parse
      @parser = IndexSchemaParser.new("index", "index.json", @document_types)
    end

    should "fail if index schema specifies an unknown document type" do
      IndexSchemaParser.any_instance.stubs(:load_json).returns({
        "document_types" => ["unknown_doc_type"],
      })
      assert_raises_message(%{Unknown document type "unknown_doc_type", in index definition in "index.json"}) { @parser.parse }
    end

    should "fail if index schema doesn't specify `document_types`" do
      IndexSchemaParser.any_instance.stubs(:load_json).returns({})
      assert_raises_message(%{Missing "document_types", in index definition in "index.json"}) { @parser.parse }
    end

    should "fail if index schema includes unknown keys" do
      IndexSchemaParser.any_instance.stubs(:load_json).returns({
        "document_types" => [],
        "foo" => "bar",
      })
      assert_raises_message(%{Unknown keys (foo), in index definition in "index.json"}) { @parser.parse }
    end
  end
end
