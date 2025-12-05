require "spec_helper"
require "spec/support/diskspace_test_helpers"
require "spec/support/connectivity_test_helpers"

RSpec.describe "HealthcheckTest" do
  include ConnectivityTestHelpers
  include DiskspaceTestHelpers

  let(:queues) do
    { "bulk" => 2, "default" => 1 }
  end
  let(:queue_latency) { 1 }

  before do
    allow_any_instance_of(Sidekiq::Stats).to receive(:queues).and_return(queues)
    allow_any_instance_of(Sidekiq::Queue).to receive(:latency).and_return(queue_latency)
    stub_connectivity_check
    stub_diskspace_check
  end

  describe "#redis_connectivity check" do
    # We only check for cannot connect because govuk_app_config has tests for this
    context "when Sidekiq CANNOT connect to Redis" do
      before do
        allow(Sidekiq.default_configuration).to receive(:redis_info).and_raise(Errno::ECONNREFUSED)
      end

      it "returns a critical status" do
        get "/healthcheck/ready"

        expect(parsed_response["status"]).to eq "critical"
      end
    end
  end

  describe "#elasticsearch_connectivity check" do
    context "when elasticsearch CANNOT be connected to" do
      before do
        stub_connectivity_fail_check
      end

      it "returns a critical status" do
        get "/healthcheck/ready"

        expect(parsed_response["status"]).to eq "critical"
        expect(parsed_response.dig("checks", "elasticsearch_connectivity", "status")).to eq "critical"
        expect(parsed_response.dig("checks", "elasticsearch_connectivity", "message")).to eq "search-api cannot connect to 1 elasticsearch cluster! \n Failing: A"
      end
    end

    context "when elasticsearch CAN be connected to" do
      it "returns an OK status" do
        get "/healthcheck/ready"

        expect(parsed_response["status"]).to eq "ok"
        expect(parsed_response.dig("checks", "elasticsearch_connectivity", "status")).to eq "ok"
      end
    end
  end

  describe "#elasticsearch_index_diskspace check" do
    context "when elasticsearch disk image has less than 20% free" do
      before do
        stub_diskspace_fail_check
      end

      it "returns a critical status" do
        get "/healthcheck/elasticsearch-diskspace"

        expect(parsed_response["status"]).to eq "critical"
      end
    end

    context "when elasticsearch disk image has more than 20% free" do
      it "returns an OK status" do
        get "/healthcheck/elasticsearch-diskspace"

        expect(parsed_response["status"]).to eq "ok"
      end
    end
  end
end
