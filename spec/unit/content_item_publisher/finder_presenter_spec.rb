require "spec_helper"
require "govuk_schemas/rspec_matchers"

RSpec.describe ContentItemPublisher::FinderPresenter do
  include GovukSchemas::RSpecMatchers

  before do
    GovukContentSchemaTestHelpers.configure do |config|
      config.schema_type = "publisher_v2"
      config.project_root = File.expand_path(Dir.pwd)
    end
  end

  finders_glob = File.join(Dir.pwd, "config", "finders", "*_finder.yml")

  Dir.glob(finders_glob).each do |config_file|
    context "Checking #{File.basename(config_file)}" do
      subject(:instance) { described_class.new(finder, timestamp) }

      let(:finder) { YAML.load_file(config_file) }
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

      it "sets the links hash" do
        email_signup_links = [finder["signup_content_id"]].compact
        parent_links = [finder["parent"]].compact
        ordered_related_items_links = [finder["ordered_related_items"]].compact
        expect(instance.present_links[:links]).to eq({ "email_alert_signup" => email_signup_links,
                                                       "parent" => parent_links,
                                                       "ordered_related_items" => ordered_related_items_links })
      end

      it "includes facet_group in the links hash if present" do
        facet_group_links = %w[facet-group-uuid]
        finder["links"] = { "facet_group" => facet_group_links }
        expect(instance.present_links[:links]).to include("facet_group" => facet_group_links)
      end

      it "uses empty arrays to remove links" do
        finder_with_no_links = finder.except("parent").except("signup_content_id").except("ordered_related_items")
        presenter_with_empty_links = described_class.new(finder_with_no_links, timestamp)

        expect(presenter_with_empty_links.present_links[:links]).to eq({ "email_alert_signup" => [],
                                                                         "parent" => [],
                                                                         "ordered_related_items" => [] })
      end
    end
  end
end
