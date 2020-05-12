require "spec_helper"
require "gds_api/test_helpers/publishing_api_v2"

RSpec.describe ContentItemPublisher::FinderEmailSignupPublisher do
  include GdsApi::TestHelpers::PublishingApi

  signups_glob = File.join(Dir.pwd, "config", "finders", "*_email_signup.yml")

  Dir.glob(signups_glob).each do |config_file|
    context "Checking #{File.basename(config_file)}" do
      subject(:instance) { described_class.new(finder, timestamp) }

      let(:finder) { YAML.load_file(config_file) }
      let(:content_id) { finder["content_id"] }
      let(:timestamp) { Time.now.iso8601 }
      let(:logger) { instance_double("Logger") }

      before do
        allow(Logger).to receive(:new).and_return(logger)
      end

      describe "#call" do
        let(:publishing_api) { instance_double("GdsApi::PublishingApi") }
        let(:payload) do
          ContentItemPublisher::FinderEmailSignupPresenter.new(finder, timestamp).present
        end

        before do
          allow(logger).to receive(:info)
          stub_any_publishing_api_put_content
          stub_any_publishing_api_patch_links
          stub_any_publishing_api_publish

          instance.call
        end

        it "drafts the email signup page" do
          assert_publishing_api_put_content(content_id, payload)
        end

        it "patches links for the email signup page" do
          assert_publishing_api_patch_links(content_id, ->(request) { JSON.parse(request.body).key?("links") })
        end

        it "publishes the email signup page to the Publishing API" do
          assert_publishing_api_publish(content_id)
        end
      end
    end
  end
end
