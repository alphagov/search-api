require "prometheus_exporter"
require "prometheus_exporter/server"
require "spec_helper"

RSpec.describe Collectors::ElasticsearchPrometheusCollector do
  subject(:metrics) { described_class.new.metrics }

  let(:cluster_status) { "green" }

  let(:nodes_stats) do
    {
      "nodes" => {
        "node-1" => {
          "fs" => {
            "total" => {
              "total_in_bytes" => 1000,
              "available_in_bytes" => 100,
            },
          },
        },
        "node-2" => {
          "fs" => {
            "total" => {
              "total_in_bytes" => 2000,
              "available_in_bytes" => 500,
            },
          },
        },
      },
    }
  end

  let(:cluster_health) do
    { "status" => cluster_status }
  end

  before do
    es = instance_double(Elasticsearch::Transport::Client)
    allow(es).to receive_message_chain(:nodes, :stats).and_return(nodes_stats)
    allow(es).to receive_message_chain(:cluster, :health).and_return(cluster_health)
    allow(Services).to receive(:elasticsearch).and_return(es)
  end

  describe "disk space" do
    let(:disk_gauge) { metrics.first }

    it "records disk space ratio per node per node" do
      expect(disk_gauge.to_h[{ node: "node-1" }]).to eq(0.1)
      expect(disk_gauge.to_h[{ node: "node-2" }]).to eq(0.25)
    end

    describe "when total is 0" do
      let(:nodes_stats) do
        {
          "nodes" => {
            "node-1" => {
              "fs" => {
                "total" => {
                  "total_in_bytes" => 0,
                  "available_in_bytes" => 0,
                },
              },
            },
          },
        }
      end
      it "raise error if total is 0 or nil" do
        expect { disk_gauge }.to raise_error(StandardError, /Node stats invalid/)
      end
    end
    describe "when hash is invalid" do
      let(:nodes_stats) do
        {
          "nodes" => {
            "node-1" => {},
          },
        }
      end
      it "raise error if total is 0 or nil" do
        expect { disk_gauge }.to raise_error(StandardError, /Node stats invalid/)
      end
    end
  end

  describe "cluster status" do
    let(:status_gauge) { metrics.last }

    shared_examples "status mapping" do |status, expected|
      context "when status is #{status}" do
        let(:cluster_status) { status }

        it "maps to #{expected}" do
          expect(status_gauge.to_h[{}]).to eq(expected)
        end
      end
    end

    include_examples "status mapping", "green", 0
    include_examples "status mapping", "yellow", 1
    include_examples "status mapping", "red", 2
    include_examples "status mapping", "unknown", 3
  end
end
