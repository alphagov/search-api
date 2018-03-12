require "spec_helper"
require "publishing_api_finder_publisher"

RSpec.describe PublishingApiFinderPublisher do
  subject(:instance) { described_class.new(finder, timestamp) }

  let(:finder) {
    YAML.load_file(File.join(Dir.pwd, "config", "advanced-search.yml"))
  }
  let(:content_id) { finder["content_id"] }
  let(:timestamp) { Time.now.iso8601 }
  let(:logger) { instance_double("Logger") }

  before do
    allow(Logger).to receive(:new).and_return(logger)
  end

  describe "#call" do
    context "with a pre-production finder" do
      let(:publishing_api) { instance_double("GdsApi::PublishingApiV2") }
      let(:payload) {
        FinderContentItemPresenter.new(finder, timestamp).present
      }

      before do
        allow(logger).to receive(:info)
        allow(GdsApi::PublishingApiV2).to receive(:new).and_return(publishing_api)
        allow(publishing_api).to receive(:put_content)
        allow(publishing_api).to receive(:patch_links)
        allow(publishing_api).to receive(:publish)

        instance.call
      end

      it "drafts the finder" do
        expect(publishing_api).to have_received(:put_content).with(content_id, payload)
      end

      it "patches links for the finder" do
        expect(publishing_api).to have_received(:patch_links)
          .with(content_id, { content_id: content_id, links: {} })
      end

      it "publishes the finder to the Publishing API" do
        expect(publishing_api).to have_received(:publish).with(content_id)
      end
    end

    context "when a finder isn't pre-production" do
      before do
        finder.delete("pre_production")
        allow(logger).to receive(:info)
      end

      it "reports that the finder is not pre-production" do
        instance.call

        expect(logger).to have_received(:info)
          .with("Not publishing Advanced search because it's not pre_production")
      end
    end
  end

  describe FinderContentItemPresenter do
    subject(:instance) { described_class.new(finder, timestamp) }

    before do
      GovukContentSchemaTestHelpers.configure do |config|
        config.schema_type = 'publisher_v2'
        config.project_root = File.expand_path(Dir.pwd)
      end
    end

    it "presents a valid payload" do
      validator = GovukContentSchemaTestHelpers::Validator.new("finder", "schema", instance.present)
      validator.valid?

      expect(validator.errors).to be_empty
    end

    it "exposes the content_id" do
      expect(instance.content_id).to eq(content_id)
    end

    it "sets the public_updated_at value" do
      expect(instance.present[:public_updated_at]).to eq(timestamp)
    end
  end
end
