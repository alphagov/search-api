require "spec_helper"
require "rake"

RSpec.describe "publishing_api", "RakeTest" do
  let(:timestamp) { Time.now.iso8601 }
  let(:task_name) { "publishing_api:publish_finder" }
  before do
    Rake::Task[task_name].reenable
    allow(ContentItemPublisher).to receive(:publish)
    stub_any_publishing_api_call
  end

  around do |example|
    Timecop.freeze(Time.parse(timestamp)) do
      example.run
    end
  end
  describe "publish_finder" do
    context "when neither FINDER_CONFIG nor EMAIL_SIGNUP_CONFIG is set" do
      it "raises an error" do
        expect {
          Rake::Task[task_name].invoke
        }.to raise_error(
          RuntimeError,
          /Please supply a valid config file name/,
        )
      end
    end
    context "when only EMAIL_SIGNUP_CONFIG is set" do
      it "publishes the email signup finder" do
        ClimateControl.modify(EMAIL_SIGNUP_CONFIG: "news_and_communications_email_signup.yml") do
          output = capture_stdout { Rake::Task[task_name].invoke }
          expect(ContentItemPublisher).to have_received(:publish).once
          expect(ContentItemPublisher)
            .to have_received(:publish)
                  .with(config: "config/finders/news_and_communications_email_signup.yml",
                        timestamp:)
          expect(output).to include("FINISHED")
        end
      end
    end

    context "when only FINDER_CONFIG is set" do
      it "publishes the finder" do
        ClimateControl.modify(FINDER_CONFIG: "news_and_communications_finder.yml") do
          output = capture_stdout { Rake::Task[task_name].invoke }
          expect(ContentItemPublisher).to have_received(:publish).once
          expect(ContentItemPublisher)
            .to have_received(:publish)
                  .with(config: "config/finders/news_and_communications_finder.yml",
                        timestamp:)
          expect(output).to include("FINISHED")
        end
      end
    end

    context "when EMAIL_SIGNUP_CONFIG and FINDER_CONFIG is set" do
      it "publishes the email signup and finder" do
        ClimateControl.modify(FINDER_CONFIG: "news_and_communications_finder.yml",
                              EMAIL_SIGNUP_CONFIG: "news_and_communications_email_signup.yml") do
          output = capture_stdout { Rake::Task[task_name].invoke }
          expect(ContentItemPublisher)
            .to have_received(:publish).twice
          expect(output).to include("FINISHED")
        end
      end
    end
  end

  describe "publishing_api:publish_supergroup_finders" do
    let(:task_name) { "publishing_api:publish_supergroup_finders" }
    it "publishes all finders and email signup finders" do
      number_of_finders = Dir.glob("config/finders/*.yml").count
      output = capture_stdout { Rake::Task[task_name].invoke }
      expect(ContentItemPublisher).to have_received(:publish).exactly(number_of_finders).times
      expect(output).to include("PUBLISHING ALL SUPERGROUP FINDERS...")
      expect(output).to include("FINISHED")
    end
  end

  describe "publishing_api:unpublish_document_finder" do
    let(:task_name) { "publishing_api:unpublish_document_finder" }
    let(:content_id) { "622e9691-4b4f-4e9c-bce1-098b0c4f5ee2" }
    let(:email_content_id) { "54fa4dca-4dfb-40a5-b860-127716f02e75" }
    it "raises an error" do
      expect {
        Rake::Task[task_name].invoke
      }.to raise_error(
        RuntimeError,
        /Please supply a valid finder config file name/,
      )
    end
    it "unpublishes the finder" do
      ClimateControl.modify(DOCUMENT_FINDER_CONFIG: "news_and_communications_finder.yml") do
        gone = { type: "gone" }.to_json
        stub_publishing_api_unpublish(content_id, body: gone)
        stub_publishing_api_unpublish(email_content_id, body: gone)

        output = capture_stdout { Rake::Task[task_name].invoke }
        expect(output).to include("UNPUBLISHING news_and_communications_finder.yml")
        expect(output).to include("FINISHED")

        assert_publishing_api_unpublish(content_id, request_json_matches(type: "gone"))
        assert_publishing_api_unpublish(email_content_id, request_json_matches(type: "gone"))
      end
    end
  end
end
