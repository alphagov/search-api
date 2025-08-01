require "spec_helper"

RSpec.describe GovukIndex::PayloadPreparer do
  describe "#prepare" do
    context "when details.parts does not exist and an attachment URL matches the slug but is not under the base path" do
      let(:payload) do
        {
          "base_path" => "/government/statistics/criminal-court-statistics-quarterly-april-to-june-2021",
          "details" => {
            "attachments" => [
              {
                "url" => "/government/publications/criminal-court-statistics-quarterly-april-to-june-2021",
                "content" => "<p>entry</p>",
                "title" => "Full bulletin",
                "attachment_type" => "html",
              },
            ],
          },
        }
      end

      it "sets link from the attachment URL" do
        allow(Indexer::AttachmentsLookup).to receive(:prepare_attachments).and_return("attachments" => payload.dig("details", "attachments"))
        prepared = described_class.new(payload).prepare
        part = prepared.dig("details", "parts").first
        expect(part["link"]).to eq("/government/publications/criminal-court-statistics-quarterly-april-to-june-2021")
      end
    end

    context "when details.parts exist and there are no attachments" do
      let(:payload) do
        {
          "base_path" => "/foreign-travel-advice/india",
          "details" => {
            "parts" => [
              {
                "slug" => "entry-requirements",
                "title" => "Entry requirements",
                "body" => [
                  { "content_type" => "text/html", "content" => "<p>entry</p>" },
                ],
              },
            ],
          },
        }
      end

      it "derives link as base_path/slug" do
        prepared = described_class.new(payload).prepare
        part = prepared.dig("details", "parts").first
        expect(part["link"]).to eq("/foreign-travel-advice/india/entry-requirements")
      end
    end
  end
end
