require "spec_helper"
require "govuk_schemas/rspec_matchers"

RSpec.describe ContentItemPublisher::FacetGroupFinderPresenter do
  include GovukSchemas::RSpecMatchers

  before do
    GovukContentSchemaTestHelpers.configure do |config|
      config.schema_type = "publisher_v2"
      config.project_root = File.expand_path(Dir.pwd)
    end
  end

  finder_config_file = File.join(Dir.pwd, "config/find-eu-exit-guidance-business.yml")
  finder_config = YAML.load_file(finder_config_file)
  finder_config["links"]["facet_group"] = %w(content_id_of_facet_group)
  finder_config["details"]["facets"] = []

  context "when finder config has facet group in it's links" do
    subject(:instance) { described_class.new(finder, timestamp) }

    let(:finder) { finder_config }
    let(:content_id) { finder["content_id"] }
    let(:timestamp) { Time.now.iso8601 }

    it "presents a valid payload" do
      expect(instance.present).to be_valid_against_publisher_schema("finder")
    end

    it "exposes the content_id" do
      expect(instance.content_id).to eq(content_id)
    end

    it "sets the public_updated_at value" do
      expect(instance.present[:public_updated_at]).to eq(timestamp)
    end

    it "sets the links hash to include facets" do
      email_signup_links = [finder["signup_content_id"]].compact
      parent_links = [finder["parent"]].compact
      ordered_related_items_links = finder_config["ordered_related_items"]
      expect(instance.present_links[:links]).to eq({ "email_alert_signup" => email_signup_links,
                                                     "parent" => parent_links,
                                                     "ordered_related_items" => ordered_related_items_links,
                                                     "facet_group" => %w(content_id_of_facet_group) })
    end

    it "uses empty arrays to remove links" do
      finder_with_no_links = finder.except("parent").except("signup_content_id").except("ordered_related_items").except("links")
      presenter_with_empty_links = described_class.new(finder_with_no_links, timestamp)

      expect(presenter_with_empty_links.present_links[:links]).to eq({ "email_alert_signup" => [],
                                                                       "parent" => [],
                                                                       "ordered_related_items" => [],
                                                                       "facet_group" => [] })
    end
  end
end
