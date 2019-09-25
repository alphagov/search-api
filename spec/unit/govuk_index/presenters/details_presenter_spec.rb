require "spec_helper"

RSpec.describe GovukIndex::DetailsPresenter do
  subject(:presented_details) { described_class.new(details: details, format: format) }

  context "licence format" do
    let(:format) { "licence" }
    let(:details) {
      {
        "continuation_link" => "http://www.on-and-on.com",
        "external_related_links" => [],
        "licence_identifier" => "1234-5-6",
        "licence_short_description" => "short description",
        "licence_overview" => [
          { "content_type" => "text/govspeak", "content" => "**overview**" },
          { "content_type" => "text/html", "content" => "<strong>overview</strong>" }
        ],
        "will_continue_on" => "on and on",
      }
    }

    it "should extract licence specific fields" do
      expect(presented_details.licence_identifier).to eq(details["licence_identifier"])
      expect(presented_details.licence_short_description).to eq(details["licence_short_description"])
    end
  end

  context "images" do
    context "document without an image" do
      let(:format) { "answer" }

      let(:details) {
        {
          "body" => "<p>Gallwch ddefnyddio’r gwasanaethau canlynol gan Gyllid a Thollau Ei Mawrhydi </p>\n\n",
          "external_related_links" => [],
        }
      }

      it "has no image" do
        expect(presented_details.image_url).to be nil
      end
    end

    context "document with an image" do
      let(:format) { "news_article" }

      let(:details) {
        {
          "image" => {
            "alt_text" => "Christmas",
            "url" => "https://assets.publishing.service.gov.uk/christmas.jpg",
          },
          "body" => "<div class=\"govspeak\"><p>We wish you a merry Christmas.</p></div>",
        }
      }

      it "has an image" do
        expect(presented_details.image_url).to eq("https://assets.publishing.service.gov.uk/christmas.jpg")
      end
    end
  end

  context "hmrc_manual format" do
    let(:format) { "hmrc_manual" }

    context "no change notes" do
      let(:details) { {} }

      it "should have no latest change note" do
        expect(presented_details.latest_change_note).to be_nil
      end
    end

    context "empty change notes" do
      let(:details) {
        { "change_notes" => [] }
      }

      it "should have no latest change note" do
        expect(presented_details.latest_change_note).to be_nil
      end
    end

    context "multiple change notes" do
      let(:details) {
        {
          "change_notes" => [
            {
              "change_note" => "Change 1",
              "title" => "Manual section A",
              "published_at" => "2017-02-05T09:30:00+00:00",
            },
            {
              "change_note" => "Change 3",
              "title" => "Manual section B",
              "published_at" => "2017-07-24T08:00:00+00:00",
            },
            {
              "change_note" => "Change 2",
              "title" => "Manual section C",
              "published_at" => "2017-05-31T14:45:00+00:00",
            }
          ],
        }
      }

      it "should combine the title and description from the most recent change note" do
        expect(presented_details.latest_change_note).to eq("Change 3 in Manual section B")
      end
    end
  end
end
