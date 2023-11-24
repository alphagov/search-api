require "spec_helper"
require "spec/support/ranker_test_helpers"
require "spec/support/diskspace_test_helpers"

RSpec.describe "HealthcheckTest" do
  include RankerTestHelpers
  include DiskspaceTestHelpers

  let(:queues) do
    { "bulk" => 2, "default" => 1 }
  end
  let(:queue_latency) { 1 }

  before do
    allow_any_instance_of(Sidekiq::Stats).to receive(:queues).and_return(queues)
    allow_any_instance_of(Sidekiq::Queue).to receive(:latency).and_return(queue_latency)
    allow_any_instance_of(Elasticsearch::API::Cluster::ClusterClient).to receive(:health).and_return("status" => "green")
    stub_ranker_status_to_be_ok
    stub_diskspace_check
  end

  describe "#redis_connectivity check" do
    # We only check for cannot connect because govuk_app_config has tests for this
    context "when Sidekiq CANNOT connect to Redis" do
      before do
        allow(Sidekiq).to receive(:redis_info).and_raise(Errno::ECONNREFUSED)
      end

      it "returns a critical status" do
        get "/healthcheck/ready"

        expect(parsed_response["status"]).to eq "critical"
      end
    end
  end

  describe "#reranker_healthcheck check" do
    # We only check for cannot connect because govuk_app_config has tests for this
    context "when reranker healthcheck fails" do
      before do
        make_use_tensorflow_serving
        stub_ranker_container_doesnt_exist
      end

      it "returns a warning status" do
        get "/healthcheck/reranker"
        expect(parsed_response["status"]).to eq "warning"
      end
    end

    context "when reranker healthcheck passes" do
      it "returns an OK status" do
        get "/healthcheck/reranker"
        expect(parsed_response["status"]).to eq "ok"
      end
    end
  end

  describe "#elasticsearch_connectivity check" do
    context "when elasticsearch CANNOT be connected to" do
      before do
        allow_any_instance_of(Elasticsearch::API::Cluster::ClusterClient).to receive(:health).and_raise(Faraday::Error)
      end

      it "returns a critical status" do
        get "/healthcheck/ready"

        expect(parsed_response["status"]).to eq "critical"
        expect(parsed_response.dig("checks", "elasticsearch_connectivity", "status")).to eq "critical"
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
