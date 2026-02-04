require "spec_helper"

RSpec.describe ContentItemPublisher do
  describe ".publish" do
    let(:timestamp) { Time.now.iso8601 }
    let(:finder) { YAML.load_file(config) }
    let(:title) { "Test finder" }
    let(:content_id) { Random.uuid }
    let(:signup_content_id) { Random.uuid }
    let(:config) do
      Tempfile.create("finder").tap { |file|
        file.write(finder.to_yaml)
        file.rewind
      }.path
    end
    let(:finder) do
      {
        "content_id" => content_id,
        "title" => title,
        "document_type" => document_type,
        "signup_content_id" => signup_content_id,
      }
    end

    before do
      stub_any_publishing_api_call
    end

    describe "publishing a finder" do
      let(:document_type) { "finder" }
      it "publishes a finder" do
        ContentItemPublisher.publish(config:, timestamp:)
        assert_publishing_api_put_content(content_id,
                                          request_json_includes("title" => title, "document_type" => "finder"))
        assert_publishing_api_patch_links(content_id, includes_links("email_alert_signup" => [signup_content_id]))
        assert_publishing_api_publish(content_id)
      end
    end
    describe "publishing a email signup" do
      let(:document_type) { "finder_email_signup" }
      it "publishes an email signup" do
        ContentItemPublisher.publish(config:, timestamp:)
        assert_publishing_api_put_content(content_id,
                                          request_json_includes("title" => title, "document_type" => "finder_email_signup"))
        assert_publishing_api_patch_links(content_id, links: {})
        assert_publishing_api_publish(content_id)
      end
    end
    describe "invalid document type" do
      let(:finder) do
        {
          "content_id" => content_id,
          "title" => title,
          "document_type" => "unknown",
          "signup_content_id" => signup_content_id,
        }
      end
      it "raises an error" do
        expect { ContentItemPublisher.publish(config:, timestamp:) }.to raise_error("Invalid document type")
      end
    end
  end
end
