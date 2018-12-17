require "spec_helper"
require "prepare_eu_exit_finder_publisher"

RSpec.describe PrepareEuExitFinderPublisher do
  subject(:instance) { described_class.new(config, timestamp) }

  let(:finder_content_id) { "finder-finder-finder" }
  let(:config) {
    [
      {
        "title" => "Having fun at the seaside",
        "slug" => "seaside-fun",
        "topic_content_id" => "seaside-seaside-seaside",
        "finder_content_id" => finder_content_id,
        "summary" => "Something"
      }
    ]
  }
  let(:timestamp) { Time.now.iso8601 }
  let(:logger) { instance_double("Logger") }


  before do
    allow(Logger).to receive(:new).and_return(logger)
  end

  describe "#call" do
    let(:publishing_api) { instance_double("GdsApi::PublishingApiV2") }
    let(:item) {
      {
        "base_path" => "/prepare-eu-exit/seaside-fun",
        "description" => nil,
        "details" => {
          "beta" => false,
          "document_noun" => "publication",
          "facets" => [],
          "filter" => {
            "all_part_of_taxonomy_tree" => ["d7bdaee2-8ea5-460e-b00d-6e9382eb6b61", "seaside-seaside-seaside"],
            "content_purpose_supergroup" => %w(services guidance_and_regulation),
            "content_store_document_type" => %w(travel_advice_index)
          },
          "show_summaries" => true,
          "summary" => "Something"
        },
        "document_type" => "finder",
        "locale" => "en",
        "phase" => "live",
        "public_updated_at" => "2018-12-07T17:19:35+00:00",
        "publishing_app" => "rummager",
        "rendering_app" => "finder-frontend",
        "routes" => [
          { "path" => "/prepare-eu-exit/seaside-fun", "type" => "exact" },
          { "path" => "/prepare-eu-exit/seaside-fun.atom", "type" => "exact" },
          { "path" => "/prepare-eu-exit/seaside-fun.json", "type" => "exact" }
        ],
        "schema_name" => "finder",
        "title" => "Having fun at the seaside – EU Exit guidance",
        "update_type" => "minor"
      }
    }
    let(:payload) {
      FinderContentItemPresenter.new(item, timestamp).present
    }

    before do
      allow(logger).to receive(:info)
      allow(GdsApi::PublishingApiV2).to receive(:new).and_return(publishing_api)
      allow(publishing_api).to receive(:put_content)
      allow(publishing_api).to receive(:patch_links)
      allow(publishing_api).to receive(:publish)

      GovukContentSchemaTestHelpers.configure do |config|
        config.schema_type = 'publisher_v2'
        config.project_root = File.expand_path(Dir.pwd)
      end

      instance.call
    end

    it "drafts the finder with the expected payload from the template" do
      expect(publishing_api).to have_received(:put_content).with(finder_content_id, payload)
    end

    it "expects the payload generated from the template to be valid" do
      validator = GovukContentSchemaTestHelpers::Validator.new("finder", "schema", payload)
      validator.valid?

      expect(validator.errors).to be_empty
    end

    it "publishes the finder to the Publishing API" do
      expect(publishing_api).to have_received(:publish).with(finder_content_id)
    end
  end
end
