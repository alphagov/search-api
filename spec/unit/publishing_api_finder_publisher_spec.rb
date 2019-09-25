require "spec_helper"
require "publishing_api_finder_publisher"

RSpec.describe PublishingApiFinderPublisher do
  ["advanced-search.yml", "find-eu-exit-guidance-business.yml"].each do |config_file|

    subject(:instance) { described_class.new(finder, timestamp) }

    let(:finder) {
      YAML.load_file(File.join(Dir.pwd, "config", config_file))
    }
    let(:content_id) { finder["content_id"] }
    let(:signup_content_id) { finder["signup_content_id"] }
    let(:timestamp) { Time.now.iso8601 }
    let(:logger) { instance_double("Logger") }

    before do
      allow(Logger).to receive(:new).and_return(logger)
    end

    describe "#call" do
      let(:publishing_api) { instance_double("GdsApi::PublishingApiV2") }
      let(:payload) {
        FinderContentItemPresenter.new(finder, timestamp).present
      }

      let(:signup_payload) {
        FinderEmailSignupContentItemPresenter.new(finder, timestamp).present
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
          .with(content_id, { content_id: content_id, links: anything })
      end

      it "publishes the finder to the Publishing API" do
        expect(publishing_api).to have_received(:publish).with(content_id)
      end

      describe "email signups" do
        it "drafts the email signup" do
          expect(publishing_api).to have_received(:put_content).with(signup_content_id, signup_payload)
        end

        it "patches links for the email signup" do
          expect(publishing_api).to have_received(:patch_links)
            .with(signup_content_id, { content_id: signup_content_id, links: {} })
        end

        it "publishes the email signup to the Publishing API" do
          expect(publishing_api).to have_received(:publish).with(signup_content_id)
        end

        it "maps filter facets to email facets in the payload" do
          if signup_content_id
            filter_facets = payload[:details]["facets"]
            email_facets = signup_payload[:details]["email_filter_facets"]

            expect(email_facets.map { |f| f["facet_id"] }).to eq(filter_facets.map { |ft| ft["key"] })

            email_facet_values = email_facets.map { |f| f["facet_choices"].map { |fc| fc["key"] } }
            filter_facet_values = filter_facets.map { |f| f["allowed_values"].map { |av| av["value"] } }

            expect(email_facet_values).to eq(filter_facet_values)
          end
        end
      end
    end
  end

  describe FinderContentItemPresenter do
    subject(:instance) { described_class.new(finder, timestamp) }

    before do
      GovukContentSchemaTestHelpers.configure do |config|
        config.schema_type = "publisher_v2"
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

  describe FinderEmailSignupContentItemPresenter do
    subject(:instance) { described_class.new(finder, timestamp) }

    before do
      GovukContentSchemaTestHelpers.configure do |config|
        config.schema_type = "publisher_v2"
        config.project_root = File.expand_path(Dir.pwd)
      end
    end

    it "presents a valid payload" do
      validator = GovukContentSchemaTestHelpers::Validator.new("finder_email_signup", "schema", instance.present)
      validator.valid?

      expect(validator.errors).to be_empty
    end
  end
end
