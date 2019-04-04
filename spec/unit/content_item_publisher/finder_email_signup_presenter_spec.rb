require "spec_helper"
require "govuk_schemas/rspec_matchers"

RSpec.describe ContentItemPublisher::FinderEmailSignupPresenter do
  include GovukSchemas::RSpecMatchers

  before do
    GovukContentSchemaTestHelpers.configure do |config|
      config.schema_type = 'publisher_v2'
      config.project_root = File.expand_path(Dir.pwd)
    end
  end

  signups_glob = File.join(Dir.pwd, "config", "finders", "*_email_signup.yml")

  Dir.glob(signups_glob).each do |config_file|
    context "Checking #{File.basename(config_file)}" do
      subject(:instance) { described_class.new(finder, timestamp) }

      let(:finder) { YAML.load_file(config_file) }
      let(:content_id) { finder["content_id"] }
      let(:timestamp) { Time.now.iso8601 }

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
end
