require 'spec_helper'

RSpec.describe 'HealthcheckTest' do
  let(:queues) {
    { "bulk" => 2, "default" => 1 }
  }
  let(:queue_latency) { 1.seconds }

  before do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Sidekiq::Stats).to receive(:queues).and_return(queues)
    allow_any_instance_of(Sidekiq::Queue).to receive(:latency).and_return(queue_latency)
    allow_any_instance_of(Elasticsearch::API::Cluster::ClusterClient).to receive(:health).and_return('status' => 'green')
    # rubocop:enable RSpec/AnyInstance
  end

  describe "#redis_connectivity check" do
    # We only check for cannot connect because govuk_app_config has tests for this
    context "when Sidekiq CANNOT connect to Redis" do
      before do
        allow(Sidekiq).to receive(:redis_info).and_raise(Errno::ECONNREFUSED)
      end

      it "returns a critical status" do
        get "/healthcheck"

        expect(parsed_response['status']).to eq 'critical'
      end
    end
  end

  describe "#elasticsearch_connectivity check" do
    context "when elasticsearch CANNOT be connected to" do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Elasticsearch::API::Cluster::ClusterClient).to receive(:health).and_raise(Faraday::Error)
        # rubocop:enable RSpec/AnyInstance
      end

      it "returns a critical status" do
        get "/healthcheck"

        expect(parsed_response['status']).to eq 'critical'
        expect(parsed_response.dig('checks', 'elasticsearch_connectivity', 'status')).to eq 'critical'
      end
    end

    context "when elasticsearch CAN be connected to" do
      it "returns an OK status" do
        get "/healthcheck"

        expect(parsed_response['status']).to eq 'ok'
        expect(parsed_response.dig('checks', 'elasticsearch_connectivity', 'status')).to eq 'ok'
      end
    end
  end

  describe "#sidekiq_queue_latency check" do
    before do
      allow(Sidekiq).to receive(:redis_info).and_return({})
    end

    context "when queue latency is 2 (seconds)" do
      let(:queue_latency) { 2.seconds }

      it "retuns an OK status" do
        get "/healthcheck"

        expect(last_response).to be_ok

        expect(parsed_response.dig('checks', 'sidekiq_queue_latency', 'status')).to eq 'ok'
      end
    end

    context "when queue latency is 5 (seconds)" do
      let(:queue_latency) { 5.seconds }

      it "retuns a warning status" do
        get "/healthcheck"

        expect(parsed_response['status']).to eq 'warning'
        expect(parsed_response.dig('checks', 'sidekiq_queue_latency', 'status')).to eq 'warning'
      end
    end


    context "when queue latency is 15 (seconds)" do
      let(:queue_latency) { 15.seconds }

      it "retuns a critical status" do
        get "/healthcheck"

        expect(parsed_response['status']).to eq('critical')
        expect(parsed_response.dig('checks', 'sidekiq_queue_latency', 'status')).to eq 'critical'
      end
    end
  end
end
