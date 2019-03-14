require "spec_helper"
require "govuk_schemas/rspec_matchers"

RSpec.describe ContentItemPublisher::FinderEmailSignupPresenter do
  include GovukSchemas::RSpecMatchers

  %w(
    finders/policy_and_engagement_email_signup.yml
    finders/news_and_communications_email_signup.yml
    finders/all_content_email_signup.yml
    finders/guidance_and_regulation_email_signup.yml
    finders/transparency_email_signup.yml
    finders/statistics_email_signup.yml
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
      expect(instance.present).to be_valid_against_schema("finder_email_signup")
    end

    it "exposes the content_id" do
      expect(instance.content_id).to eq(content_id)
    end

    it "sets the public_updated_at value" do
      expect(instance.present[:public_updated_at]).to eq(timestamp)
    end
  end
end
