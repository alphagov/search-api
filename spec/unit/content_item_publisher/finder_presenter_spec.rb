require "spec_helper"
require "govuk_schemas/rspec_matchers"

RSpec.describe ContentItemPublisher::FinderPresenter do
  include GovukSchemas::RSpecMatchers

  %w(
    finders/policy_and_engagement.yml
    finders/news_and_communications.yml
    finders/all_content.yml
    finders/guidance_and_regulation.yml
    finders/transparency.yml
    finders/statistics.yml
  ).each do |config_file|

    subject(:instance) { described_class.new(finder, timestamp) }

    let(:finder) { YAML.load_file(File.join(Dir.pwd, "config", config_file)) }
    let(:content_id) { finder["content_id"] }
    let(:timestamp) { Time.now.iso8601 }

    before do
      GovukContentSchemaTestHelpers.configure do |config|
        config.schema_type = 'publisher_v2'
        config.project_root = File.expand_path(Dir.pwd)
      end
    end

    it "presents a valid payload" do
      expect(instance.present).to be_valid_against_schema("finder")
    end

    it "exposes the content_id" do
      expect(instance.content_id).to eq(content_id)
    end

    it "sets the public_updated_at value" do
      expect(instance.present[:public_updated_at]).to eq(timestamp)
    end

    it "sets the links hash" do
      expect(instance.present_links[:links]).to eq({ "email_alert_signup" => [finder['signup_content_id']],
                                                     "parent" => [] })
    end

    it "uses empty arrays to remove links" do
      finder.except!("signup_content_id")
      expect(instance.present_links[:links]).to eq({ "email_alert_signup" => [],
                                                     "parent" => [] })
    end
  end
end
