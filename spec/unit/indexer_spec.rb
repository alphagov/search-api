require "spec_helper"

RSpec.describe Indexer do
  describe ".find_content_id" do
    let(:logger) { Logging.logger[described_class] }
    let(:content_id) { SecureRandom.uuid }
    let(:base_path) { "/base-path" }

    context "when publishing api has the content item" do
      it "returns the content id" do
        stub_publishing_api_has_lookups(base_path => content_id)
        expect(described_class.find_content_id(base_path, logger)).to eq(content_id)
      end
    end

    context "when the lookup times out" do
      before do
        publishing_api_adapter = instance_double(GdsApi::PublishingApi)
        allow(GdsApi::PublishingApi)
          .to receive(:new)
          .and_return(publishing_api_adapter)
        allow(publishing_api_adapter)
          .to receive(:lookup_content_id)
          .and_raise(GdsApi::TimedOutException)
        allow(logger).to receive(:error)
      end

      it "logs the error and raises a Indexer::PublishingApiError" do
        expect { described_class.find_content_id(base_path, logger) }.to raise_error(Indexer::PublishingApiError) do
          expect(logger)
            .to have_received(:error)
            .with("Timeout looking up content ID for #{base_path}")
        end
      end
    end

    context "when an HTTP error is raised" do
      let(:error_code) { 500 }
      let(:error_message) { "An error message" }

      before do
        publishing_api_adapter = instance_double(GdsApi::PublishingApi)
        allow(GdsApi::PublishingApi)
          .to receive(:new)
          .and_return(publishing_api_adapter)
        allow(publishing_api_adapter)
          .to receive(:lookup_content_id)
          .and_raise(GdsApi::HTTPErrorResponse.new(error_code, error_message))
        allow(logger).to receive(:error)
      end

      it "logs the error and raises a Indexer::PublishingApiError" do
        expect { described_class.find_content_id(base_path, logger) }.to raise_error(Indexer::PublishingApiError) do
          expect(logger)
            .to have_received(:error)
            .with("HTTP error looking up content ID for #{base_path}: #{error_message}")
        end
      end
    end
  end
end
