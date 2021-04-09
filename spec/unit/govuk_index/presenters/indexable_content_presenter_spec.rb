require "spec_helper"

RSpec.describe GovukIndex::IndexableContentPresenter do
  subject do
    described_class.new(
      format: format,
      details: details,
      sanitiser: GovukIndex::IndexableContentSanitiser.new,
    )
  end

  let(:format) { "help_page" }

  context "govspeak and html in body fields" do
    let(:details) do
      {
        "body" => [
          { "content_type" => "text/govspeak", "content" => "**hello**" },
          { "content_type" => "text/html", "content" => "<strong>hello</strong>" },
        ],
      }
    end

    it "extracts sanitised text from html" do
      expect(subject.indexable_content).to eq("hello")
    end
  end

  context "details with parts" do
    let(:details) do
      {
        "parts" => [
          {
            "title" => "title 1",
            "slug" => "title-1",
            "body" => [
              { "content_type" => "text/govspeak", "content" => "**hello**" },
              { "content_type" => "text/html", "content" => "<strong>hello</strong>" },
            ],
          },
          {
            "title" => "title 2",
            "slug" => "title-2",
            "body" => [
              { "content_type" => "text/govspeak", "content" => "**goodbye**" },
              { "content_type" => "text/html", "content" => "<strong>goodbye</strong>" },
            ],
          },
        ],
      }
    end

    it "extracts content from details with parts" do
      expect(subject.indexable_content).to eq("title 1\n\nhello\n\ntitle 2\n\ngoodbye")
    end
  end

  context "additional specified indexable content keys" do
    context "transaction format" do
      let(:format) { "transaction" }
      let(:details) do
        {
          "external_related_links" => [],
          "introductory_paragraph" => [
            { "content_type" => "text/govspeak", "content" => "**introductory paragraph**" },
            { "content_type" => "text/html", "content" => "<strong>introductory paragraph</strong>" },
          ],
          "more_information" => "more information",
          "start_button_text" => "Start now",
        }
      end

      it "extracts additional indexable content keys when they have been specified" do
        expect(subject.indexable_content).to eq("introductory paragraph\n\nmore information")
      end
    end

    context "flood_and_coastal_erosion_risk_management_research_report format" do
      let(:format) { "flood_and_coastal_erosion_risk_management_research_report" }
      let(:details) do
        {
          "metadata" => {
            "project_code" => "ABC",
          },
        }
      end

      it "extracts additional indexable content keys when they have been specified" do
        expect(subject.indexable_content).to eq("ABC")
      end
    end
  end

  context "contact format" do
    let(:format) { "contact" }
    let(:details) do
      {
        "title" => "Title",
        "description" => "Description",
        "contact_groups" => [
          {
            "slug" => "slug-1",
            "title" => "Title 1",
          },
          {
            "slug" => "slug-2",
            "title" => "Title 2",
          },
        ],
      }
    end

    it "extracts contact format indexable content correctly" do
      expect(subject.indexable_content).to eq("Title\n\n\nDescription\n\n\nTitle 1\n\n\nTitle 2")
    end
  end

  context "smart_answer format" do
    let(:format) { "smart_answer" }
    let(:details) do
      {
        "hidden_search_terms" => ["hidden 1", "hidden 2"],
      }
    end

    it "hidden_search_terms is correctly indexed" do
      expect(subject.indexable_content).to eq("hidden 1\n\n\nhidden 2")
    end
  end
end
