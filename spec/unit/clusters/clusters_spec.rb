require 'spec_helper'
require 'spec/unit/helpers/cluster_test_helpers'

RSpec.describe Clusters do
  include ClusterTestHelpers

  subject(:clusters) { described_class }

  describe "#default_cluster" do
    it "returns the correct cluster key" do
      expect(clusters.default_cluster).to be_instance_of Clusters::Cluster
      expect(clusters.default_cluster.key).to eq(default_key)
    end
  end

  describe "#count" do
    it "returns the number of active clusters" do
      expect(described_class.count).to eq(described_class.active.count)
    end
  end

  describe "#active" do
    it "returns an array of active clusters" do
      expect(clusters.active).to all be_instance_of Clusters::Cluster
      expect(clusters.active.map(&:key)).to include default_key
      clusters.active.each { |cluster|
        expect(cluster.inactive?).to be false
      }
    end
  end

  describe "#get_cluster" do
    it "returns an active cluster" do
      valid_cluster_keys.each { |key|
        cluster = clusters.get_cluster(key)
        expect(cluster).to be_instance_of Clusters::Cluster
        expect(cluster.key).to eq(key)
        expect(cluster.uri.present?).to be true
      }
    end

    it "raises ClusterNotFoundError for any other value" do
      invalid_cluster_keys.each { |key|
        expect do
          clusters.get_cluster(key)
        end.to raise_error Clusters::ClusterNotFoundError
      }
    end
  end

  describe "#validate_cluster_key!" do
    it "does not raise an error for valid cluster keys" do
      valid_cluster_keys.each { |key|
        expect do
          clusters.validate_cluster_key!(key)
        end.not_to raise_error
      }
    end

    it "raises an error for any other value" do
      invalid_cluster_keys.each { |key|
        expect do
          clusters.validate_cluster_key!(key)
        end.to raise_error Clusters::InvalidClusterError
      }
    end
  end

  describe "#cluster_keys" do
    it "returns correct cluster keys" do
      expect(clusters.cluster_keys).to include default_key
      expect(clusters.cluster_keys).to eq valid_cluster_keys
    end
  end
end
