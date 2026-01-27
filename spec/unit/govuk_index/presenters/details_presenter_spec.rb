require "spec_helper"

RSpec.describe GovukIndex::DetailsPresenter do
  subject(:presented_details) { described_class.new(details:, format:) }

  context "licence format" do
    let(:format) { "licence" }
    let(:details) do
      {
        "continuation_link" => "http://www.on-and-on.com",
        "external_related_links" => [],
        "licence_identifier" => "1234-5-6",
        "licence_short_description" => "short description",
        "licence_overview" => [
          { "content_type" => "text/govspeak", "content" => "**overview**" },
          { "content_type" => "text/html", "content" => "<strong>overview</strong>" },
        ],
        "will_continue_on" => "on and on",
      }
    end

    it "extracts licence specific fields" do
      expect(presented_details.licence_identifier).to eq(details["licence_identifier"])
      expect(presented_details.licence_short_description).to eq(details["licence_short_description"])
    end
  end

  context "images" do
    context "document without an image" do
      let(:format) { "answer" }

      let(:details) do
        {
          "body" => "<p>Gallwch ddefnyddio’r gwasanaethau canlynol gan Gyllid a Thollau Ei Mawrhydi </p>\n\n",
          "external_related_links" => [],
        }
      end

      it "has no image" do
        expect(presented_details.image_url).to be nil
      end
    end

    context "document with an image" do
      let(:format) { "news_article" }

      let(:details) do
        {
          "image" => {
            "alt_text" => "Christmas",
            "url" => "https://assets.publishing.service.gov.uk/christmas.jpg",
          },
          "body" => "<div class=\"govspeak\"><p>We wish you a merry Christmas.</p></div>",
        }
      end

      it "has an image" do
        expect(presented_details.image_url).to eq("https://assets.publishing.service.gov.uk/christmas.jpg")
      end
    end
  end

  context "hmrc_manual format" do
    let(:format) { "hmrc_manual" }

    context "no change notes" do
      let(:details) { {} }

      it "has no latest change note" do
        expect(presented_details.latest_change_note).to be_nil
      end
    end

    context "empty change notes" do
      let(:details) do
        { "change_notes" => [] }
      end

      it "has no latest change note" do
        expect(presented_details.latest_change_note).to be_nil
      end
    end

    context "multiple change notes" do
      let(:details) do
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
            },
          ],
        }
      end

      it "combines the title and description from the most recent change note" do
        expect(presented_details.latest_change_note).to eq("Change 3 in Manual section B")
      end
    end
  end

  context "publication format" do
    let(:format) { "publication" }
    let(:details) do
      {
        "document_type_label" => "Publication",
      }
    end

    it "extracts the document type label" do
      expect(presented_details.document_type_label).to eq("Publication")
    end

    context "it has an attachment with a command paper number" do
      let(:details) do
        {
          "attachments" => [
            {
              "command_paper_number" => "Cm. 1234",
            },
          ],
        }
      end

      it "has an official document" do
        expect(presented_details.has_official_document?).to be true
      end

      it "has a command paper" do
        expect(presented_details.has_command_paper?).to be true
      end

      it "does not have an act paper" do
        expect(presented_details.has_act_paper?).to be false
      end
    end

    context "it has an attachment that is an unnumbered command paper" do
      let(:details) do
        {
          "attachments" => [
            {
              "unnumbered_command_paper" => true,
            },
          ],
        }
      end

      it "has an official document" do
        expect(presented_details.has_official_document?).to be true
      end

      it "has a command paper" do
        expect(presented_details.has_command_paper?).to be true
      end

      it "does not have an act paper" do
        expect(presented_details.has_act_paper?).to be false
      end
    end

    context "it has an attachment with an hoc paper number" do
      let(:details) do
        {
          "attachments" => [
            {
              "hoc_paper_number" => "Hoc. 1234",
            },
          ],
        }
      end

      it "has an official document" do
        expect(presented_details.has_official_document?).to be true
      end

      it "does not have a command paper" do
        expect(presented_details.has_command_paper?).to be false
      end

      it "has an act paper" do
        expect(presented_details.has_act_paper?).to be true
      end
    end

    context "it has an attachment that is an unnumbered hoc paper" do
      let(:details) do
        {
          "attachments" => [
            {
              "unnumbered_hoc_paper" => true,
            },
          ],
        }
      end

      it "has an official document" do
        expect(presented_details.has_official_document?).to be true
      end

      it "does not have a command paper" do
        expect(presented_details.has_command_paper?).to be false
      end

      it "has an act paper" do
        expect(presented_details.has_act_paper?).to be true
      end
    end

    context "it has no attachments that are hoc papers or command papers" do
      let(:details) do
        {
          "attachments" => [],
        }
      end

      it "has an official document" do
        expect(presented_details.has_official_document?).to be false
      end

      it "does not have a command paper" do
        expect(presented_details.has_command_paper?).to be false
      end

      it "has an act paper" do
        expect(presented_details.has_act_paper?).to be false
      end
    end

    context "it has no attachments" do
      let(:details) do
        {}
      end

      it "has an official document" do
        expect(presented_details.has_official_document?).to be nil
      end

      it "does not have a command paper" do
        expect(presented_details.has_command_paper?).to be nil
      end

      it "has an act paper" do
        expect(presented_details.has_act_paper?).to be nil
      end
    end
  end

  context "organisation" do
    let(:format) { "organisation" }
    let(:details) do
      {
        "acronym" => "Companies House",
        "brand" => "department-for-business-trade",
        "logo" => {
          "image" => {
            "url" => "https://assets.publishing.service.gov.uk/media/67f65f2bb7e44efc70acc3db/test_logo.png",
          },
          "crest" => "single-identity",
          "formatted_title" => "Companies House",
        },
        "organisation_govuk_status" => {
          "status" => "live",
          "updated_at" => nil,
          "url" => nil,
        },
        "organisation_type" => "executive_agency",
      }
    end

    it("extracts organisation-specific fields") do
      expect(presented_details.acronym).to eq(details["acronym"])
      expect(presented_details.closed_at).to be_nil
      expect(presented_details.logo_formatted_title).to eq(details["logo"]["formatted_title"])
      expect(presented_details.logo_url).to eq(details["logo"]["image"]["url"])
      expect(presented_details.organisation_brand).to eq(details["brand"])
      expect(presented_details.organisation_closed_state).to be_nil
      expect(presented_details.organisation_crest).to eq(details["logo"]["crest"])
      expect(presented_details.organisation_state).to eq(details["organisation_govuk_status"]["status"])
      expect(presented_details.organisation_type).to eq(details["organisation_type"])
    end
  end

  context "closed organisation" do
    let(:format) { "organisation" }
    let(:details) do
      {
        "organisation_govuk_status" => {
          "status" => "changed_name",
          "updated_at" => "2024-06-01T00:00:00.000+01:00",
          "url" => nil,
        },
      }
    end

    it("transforms closed organisation status fields to preserve behaviour of government index") do
      expect(presented_details.organisation_state).to eq("closed")
      expect(presented_details.organisation_closed_state).to eq("changed_name")
      expect(presented_details.closed_at).to eq("2024-06-01T00:00:00.000+01:00")
    end
  end

  context "any format" do
    let(:format) { "any" }
    context "it has a start and an end date" do
      let(:details) do
        {
          "start_date" => "2024-06-01T00:00:00.000+01:00",
          "end_date" => "2024-06-02T00:00:00.000+01:00",
          "opening_date" => "2024-06-03T00:00:00.000+01:00",
          "closing_date" => "2024-06-04T00:00:00.000+01:00",
        }
      end

      it("presents the start and end date values") do
        expect(presented_details.start_date).to eq("2024-06-01T00:00:00.000+01:00")
        expect(presented_details.end_date).to eq("2024-06-02T00:00:00.000+01:00")
      end
    end

    context "it has an opening and a closing date" do
      let(:details) do
        {
          "opening_date" => "2024-06-01T00:00:00.000+01:00",
          "closing_date" => "2024-06-02T00:00:00.000+01:00",
        }
      end

      it("presents the start and end date values") do
        expect(presented_details.start_date).to eq("2024-06-01T00:00:00.000+01:00")
        expect(presented_details.end_date).to eq("2024-06-02T00:00:00.000+01:00")
      end
    end
  end
end
