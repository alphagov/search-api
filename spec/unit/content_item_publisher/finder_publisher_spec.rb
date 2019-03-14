require "spec_helper"

RSpec.describe ContentItemPublisher::FinderPublisher do
  %w(
    finders/policy_and_engagement.yml
    finders/news_and_communications.yml
    finders/guidance_and_regulation.yml
    finders/transparency.yml
    finders/all_content.yml
    finders/statistics.yml
  ).each do |config_file|

    subject(:instance) { described_class.new(finder, timestamp) }

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
        ContentItemPublisher::FinderPresenter.new(finder, timestamp).present
      }

      before do
        allow(logger).to receive(:info)
        allow(Services.publishing_api).to receive(:put_content)
        allow(Services.publishing_api).to receive(:patch_links)
        allow(Services.publishing_api).to receive(:publish)

        instance.call
      end

      it "drafts the finder" do
        expect(Services.publishing_api).to have_received(:put_content).with(content_id, payload)
      end

      it "patches links for the finder" do
        expect(Services.publishing_api).to have_received(:patch_links)
          .with(content_id, { content_id: content_id, links: anything })
      end

      it "publishes the finder to the Publishing API" do
        expect(Services.publishing_api).to have_received(:publish).with(content_id)
      end
    end
  end
end
