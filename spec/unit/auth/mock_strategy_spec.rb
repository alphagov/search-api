require "spec_helper"

RSpec.describe Auth::MockStrategy do
  let(:env) { { "PATH_INFO" => "/resource" } }

  context "when signin is invalid" do
    around do |example|
      ClimateControl.modify(GDS_SSO_MOCK_INVALID: "1") { example.run }
    end

    it "fails authentication" do
      response = described_class.new(env)._run!
      expect(response.result).to be :failure
    end
  end

  context "when signin is valid" do
    around do |example|
      ClimateControl.modify(GDS_SSO_MOCK_INVALID: nil) { example.run }
    end

    it "successfully authenticates" do
      response = described_class.new(env)._run!
      expect(response.result).to be :success
    end

    it "has a mock user" do
      response = described_class.new(env)._run!
      expect(response.user).to match(
        a_hash_including(
          "name" => "Mock API User",
          "email" => "mock.user@example.com",
        )
      )
    end
  end
end
