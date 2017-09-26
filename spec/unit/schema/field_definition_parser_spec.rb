require 'spec_helper'

RSpec.describe FieldDefinitionParser do
  context "after loading definitions" do
    before do
      @definitions = described_class.new(File.expand_path('../../../config/schema', File.dirname(__FILE__))).parse
    end

    it "recognise the `link` field definition" do
      assert_equal "link", @definitions["link"].name
    end

    it "know that the `link` field has type `identifier`" do
      assert_equal "identifier", @definitions["link"].type.name
    end

    it "know that the `link` field has a description" do
      refute @definitions["link"].description.empty?
    end

    it "know that the `link` field has no children" do
      assert @definitions["link"].children.nil?
    end

    it "know that the `attachments` field has a child of `title` of type searchable_text" do
      assert_equal "searchable_text", @definitions["attachments"].children["title"].type.name
    end

    it "be able to merge two field definitions" do
      value1 = { "label" => "Value1", "value" => "value1" }
      value2 = { "label" => "Value2", "value" => "value2" }
      value3 = { "label" => "Value3", "value" => "value3" }
      definition1 = FieldDefinition.new("foo", "string", {}, "", nil, [value1, value2])
      definition2 = FieldDefinition.new("foo", "string", {}, "", nil, [value2, value3])
      merged = definition2.merge(definition1)

      assert_equal "foo", merged.name
      assert_equal "string", merged.type
      assert_equal [value1, value2, value3], merged.expanded_search_result_fields.sort_by { |item| item["value"] }
    end
  end
end
