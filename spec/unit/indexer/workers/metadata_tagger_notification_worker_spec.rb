require 'spec_helper'
require 'gds_api/email_alert_api'

# rubocop:disable RSpec/FilePath, RSpec/VerifiedDoubles
RSpec.describe Indexer::MetadataTaggerNotificationWorker do
  subject(:instance) { described_class.new }

  let(:metadata) {
    {
      "sector_business_area" => %w(aerospace agriculture),
      "business_activity" => %w(yes),
      "appear_in_find_eu_exit_guidance_business_finder" => "yes"
    }
  }

  let(:document) do
    {
      "content_id" => "9d58f37a-7ebe-436a-b7fc-bdb5e287a2b3",
      "title" => "Operating in the EU after Brexit",
      "description" => "When the UK leaves the EU, the way businesses both offer services in the EU and operate will change.",
      "publishing_app" => "whitehall",
      "content_store_document_type" => "detailed_guide",
      "public_timestamp" => "2018-01-02 10:10:20.002",
      "link" => "/guidance/operating-in-the-eu-after-brexit",
      "taxons" => { a: 'a', b: 'b' },
      "organisation_content_ids" => ["16f03199-c4f4-408f-844c-bd8489b0a06b"],
    }
  end

  let(:payload) { instance.email_alert_api_payload(document, metadata) }

  describe "#email_alert_api_payload" do
    it "presents metadata as tags" do
      expect(payload[:tags]).to eq(metadata)
    end

    it "presents common document attributes" do
      %i[content_id title description publishing_app].each do |key|
        expect(payload[key]).to eq(document[key.to_s])
      end
    end

    it "presents urgency and priority fields" do
      expect(payload[:urgent]).to be true
      expect(payload[:priority]).to eq("high")
    end

    it "presents fields mapped to appropriate keys" do
      expect(payload[:base_path]).to eq(document["link"])
      expect(payload[:document_type]).to eq(document["content_store_document_type"])
      expect(payload[:public_updated_at]).to eq(document["public_timestamp"])
    end

    it "presents links" do
      links = payload[:links]
      expect(links[:content_id]).to eq(document["content_id"])
      expect(links[:organisations]).to eq(document["organisation_content_ids"])
      expect(links[:taxons]).to eq(document["taxons"])
    end
  end

  describe "#perform" do
    let(:item_in_search) { { "_source" => document } }
    let(:mock_email_alert_api) { instance_double(GdsApi::EmailAlertApi, send_alert: :sent!) }

    before do
      allow(GdsApi::EmailAlertApi).to receive(:new).and_return(mock_email_alert_api)
    end

    it "sends an appropriate payload to email-alert-api" do
      instance.perform(item_in_search, metadata)

      expect(mock_email_alert_api).to have_received(:send_alert).with(payload)
    end
  end

  describe "#perform when email-alert-api returns a conflict" do
    let(:item_in_search) { { "_source" => document } }
    let(:conflicting_email_alert_api) { double(:email_alert_api) }

    before do
      allow(described_class).to receive(:email_alert_api).and_return(conflicting_email_alert_api)
      allow(conflicting_email_alert_api).to receive(:send_alert).and_return(GdsApi::HTTPConflict.new("nope"))
    end

    it "rescues the error" do
      expect { instance.perform(item_in_search, metadata) }.not_to raise_error
    end
  end
end
# rubocop:enable RSpec/FilePath, RSpec/VerifiedDoubles
