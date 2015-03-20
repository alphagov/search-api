require "test_helper"
require "schema/field_definitions"

class FieldDefinitionsTest < ShouldaUnitTestCase

  context "after loading definitions" do
    setup do
      @definitions = FieldDefinitionParser.new(File.expand_path('../../../config/schema', File.dirname(__FILE__))).parse
    end

    should "recognise the `link` field definition" do
      assert_equal "link", @definitions["link"].name
    end

    should "know that the `link` field has type `identifier`" do
      assert_equal "identifier", @definitions["link"].type.name
    end

    should "know that the `link` field has a description" do
      refute @definitions["link"].description.empty?
    end

    should "know that the `link` field has no children" do
      assert @definitions["link"].children.nil?
    end

    should "know that the `attachments` field has a child of `title` of type searchable_text" do
      assert_equal "searchable_text", @definitions["attachments"].children["title"].type.name
    end
  end

end
