require "spec_helper"

RSpec.describe ContentItemPublisher::FacetGroupFinderPublisher do
  before do
    GovukContentSchemaTestHelpers.configure do |config|
      config.schema_type = 'publisher_v2'
      config.project_root = File.expand_path(Dir.pwd)
    end
  end

  finder_config_file = File.join(Dir.pwd, "config/find-eu-exit-guidance-business.yml")
  finder_config = YAML.load_file(finder_config_file)
  finder_config["links"]["facet_group"] = %w(content_id_of_facet_group)
  finder_config["details"]["facets"] = []

  context "when publishing finder config has facet group in it's links" do
    subject(:instance) { described_class.new(finder, timestamp) }

    let(:finder) { finder_config }
    let(:content_id) { finder["content_id"] }
    let(:timestamp) { Time.now.iso8601 }
    let(:logger) { instance_double("Logger") }

    before do
      allow(Logger).to receive(:new).and_return(logger)
    end

    describe "#call" do
      let(:publishing_api) { instance_double("GdsApi::PublishingApiV2") }
      let(:payload) {
        ContentItemPublisher::FacetGroupFinderPresenter.new(finder, timestamp).present
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
          .with(content_id,
            {
              content_id: content_id,
              links:
                {
                  "email_alert_signup" => [finder_config["signup_content_id"]],
                  "facet_group" => %w(content_id_of_facet_group),
                  "ordered_related_items" => finder_config["ordered_related_items"],
                  "parent" => []
                }
            })
      end

      it "publishes the finder to the Publishing API" do
        expect(Services.publishing_api).to have_received(:publish).with(content_id)
      end
    end
  end
end
