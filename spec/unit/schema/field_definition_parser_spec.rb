require "spec_helper"

RSpec.describe FieldDefinitionParser do
  context "after loading definitions" do
    before do
      @definitions = described_class.new(File.expand_path("../../../config/schema", File.dirname(__FILE__))).parse
    end

    it "recognise the `link` field definition" do
      expect(@definitions["link"].name).to eq("link")
    end

    it "know that the `link` field has type `identifier`" do
      expect(@definitions["link"].type.name).to eq("identifier")
    end

    it "know that the `link` field has a description" do
      expect(@definitions["link"].description).not_to be_empty
    end

    it "know that the `link` field has no children" do
      expect(@definitions["link"].children).to be_nil
    end

    it "know that the `attachments` field has a child of `title` of type searchable text" do
      expect(@definitions["attachments"].children["title"].type.name).to eq("searchable_text")
    end
  end
end
