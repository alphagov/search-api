require "spec_helper"
require "spec/unit/helpers/cluster_test_helpers"

RSpec.describe Clusters::Cluster do
  include ClusterTestHelpers

  subject(:cluster) do
    described_class.new(
      key: default["key"],
      uri_key: default["uri_key"],
      default: default["default"],
    )
  end

  let(:default) { es_config["clusters"].find { |cluster| cluster["default"] } }
  let(:default_uri) { es_config[default["uri_key"]] }

  describe "#uri" do
    it "returns the uri from the config" do
      expect(cluster.uri).to eq(default_uri)
    end
  end

  describe "#inactive?" do
    context "when a cluster is defined in the elasticsearch.yml config file" do
      it "responds false when uri is present" do
        expect(cluster.inactive?).to be false
      end
    end

    context "when a cluster not defined in the elasticsearch.yml config file" do
      subject(:cluster) { described_class.new(key: "Z", uri_key: "base_uri_c") }

      it "responds true" do
        expect(cluster.inactive?).to be true
      end
    end
  end

  def es_config
    ElasticsearchConfig.new.config
  end
end
