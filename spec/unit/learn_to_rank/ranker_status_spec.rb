require "spec_helper"
require "spec/support/ranker_test_helpers"

RSpec.describe LearnToRank::RankerStatus do
  include RankerTestHelpers

  subject(:status) { described_class.new(timeout: 0.001) }

  def stub_ranker_status_request
    stub_request(:any, "http://0.0.0.0:8501/v1/models/ltr")
  end

  context "when TENSORFLOW_SAGEMAKER_ENDPOINT envvar is unset" do
    context "when the reranker is not available" do
      it "is unhealthy" do
        stub_ranker_container_doesnt_exist

        expect(status).to_not be_healthy
        expect(status.errors.first).to include("StatusResponseInvalid")
      end
    end

    context "when the reranker takes too long to respond" do
      it "is unhealthy" do
        stub_ranker_requests_timeout
        expect(status).to_not be_healthy
        expect(status.errors.first).to include("RankerServerError")
      end
    end

    context "when the reranker response is invalid" do
      it "is unhealthy" do
        stub_ranker_status_request.to_return(status: 400)
        expect(status.errors.first).to include("StatusResponseInvalid")
      end
    end

    context "when there is no model version defined" do
      it "is unhealthy" do
        stub_ranker_status_request.to_return(
          status: 200,
          body: {
            "model_version_status": [],
          }.to_json,
        )
        expect(status).to_not be_healthy
        expect(status.errors.first).to include("ModelUndefined")
      end
    end

    context "when the model is not in a healthy state" do
      it "is unhealthy" do
        stub_ranker_status_request.to_return(
          status: 200,
          body: {
            "model_version_status": [
              {
                "version": "1",
                "state": "UNAVAILABLE",
                "status": {
                  "error_code": "CRITICAL",
                  "error_message": "It is broken",
                },
              },
            ],
          }.to_json,
        )
        expect(status).to_not be_healthy
        expect(status.errors.first).to include("ModelStateUnhealthy")
      end
    end

    context "when the model does not have a healthy status" do
      it "is unhealthy" do
        stub_ranker_status_request.to_return(
          status: 200,
          body: {
            "model_version_status": [
              {
                "version": "1",
                "state": "AVAILABLE",
                "status": {
                  "error_code": "CRITICAL",
                  "error_message": "It is broken",
                },
              },
            ],
          }.to_json,
        )
        expect(status).to_not be_healthy
        expect(status.errors.first).to include("ModelStatusUnhealthy: Status: 'CRITICAL'. Error: It is broken")
      end
    end

    context "when the model is healthy" do
      it "returns healthy" do
        stub_ranker_status_to_be_ok
        expect(status.errors).to be_empty
        expect(status).to be_healthy
      end
    end
  end
end
