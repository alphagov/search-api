require "test_helper"
require "schema/field_definitions"

class FieldDefinitionsTest < ShouldaUnitTestCase

  context "after loading definitions" do
    setup do
      @definitions = FieldDefinitions.parse(File.expand_path('../../../config/schema', File.dirname(__FILE__)))
    end

    should "recognise the `link` field definition" do
      assert_equal "link", @definitions.get("link").name
    end

    should "know that the `link` field has type `identifier`" do
      assert_equal "identifier", @definitions.get("link").type.name
    end

    should "know that the `link` field has a description" do
      refute @definitions.get("link").description.empty?
    end

    should "know that the `link` field has no children" do
      assert @definitions.get("link").children.nil?
    end

    should "know that the `attachments` field has a child of `title` of type searchable_text" do
      assert_equal "searchable_text", @definitions.get("attachments").children.get("title").type.name
    end

    should "raise an error for unknown fields" do
      exc = assert_raises(RuntimeError) do
        @definitions.get("unknown")
      end
      assert_equal %{Undefined field "unknown"}, exc.message
    end
  end

end
