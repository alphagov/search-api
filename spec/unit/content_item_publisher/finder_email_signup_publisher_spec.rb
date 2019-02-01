require "spec_helper"

RSpec.describe ContentItemPublisher::FinderEmailSignupPublisher do
  subject(:instance) { described_class.new(finder, timestamp) }

  let(:config_file) { "finders/news_and_communications_email_signup.yml" }
  let(:finder) { YAML.load_file(File.join(Dir.pwd, "config", config_file)) }
  let(:content_id) { finder["content_id"] }
  let(:timestamp) { Time.now.iso8601 }
  let(:logger) { instance_double("Logger") }

  before do
    allow(Logger).to receive(:new).and_return(logger)
  end

  describe "#call" do
    let(:publishing_api) { instance_double("GdsApi::PublishingApiV2") }
    let(:payload) {
      ContentItemPublisher::FinderEmailSignupPresenter.new(finder, timestamp).present
    }

    before do
      allow(logger).to receive(:info)
      allow(GdsApi::PublishingApiV2).to receive(:new).and_return(publishing_api)
      allow(publishing_api).to receive(:put_content)
      allow(publishing_api).to receive(:patch_links)
      allow(publishing_api).to receive(:publish)

      instance.call
    end

    it "drafts the email signup page" do
      expect(publishing_api).to have_received(:put_content).with(content_id, payload)
    end

    it "patches links for the email signup page" do
      expect(publishing_api).to have_received(:patch_links)
        .with(content_id, { content_id: content_id, links: anything })
    end

    it "publishes the email signup page to the Publishing API" do
      expect(publishing_api).to have_received(:publish).with(content_id)
    end
  end
end
