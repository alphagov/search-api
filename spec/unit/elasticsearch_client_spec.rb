RSpec.describe ElasticsearchClient do
  describe ".es7?" do
    let(:es_client) { double("Elasticsearch") }
    let(:version_info) { nil }

    after do
      ElasticsearchClient.reload_version
    end

    before do
      allow(Services).to receive(:elasticsearch).and_return(es_client)
      allow(es_client).to receive_messages(info: version_info)
    end

    context "when USE_ELASTICSEARCH_7 is set" do
      it "returns true and does not query Elasticsearch" do
        ClimateControl.modify USE_ELASTICSEARCH_6: nil,  USE_ELASTICSEARCH_7: "true" do
          expect(described_class.es7?).to eq(true)

          expect(es_client).not_to have_received(:info)
        end
      end
    end

    context "when USE_ELASTICSEARCH_6 is set" do
      it "returns false and does not query Elasticsearch" do
        ClimateControl.modify USE_ELASTICSEARCH_6: "true", USE_ELASTICSEARCH_7: nil do
          expect(described_class.es7?).to eq(false)

          expect(es_client).not_to have_received(:info)
        end
      end
    end

    context "when no override is set" do
      around do |example|
        ClimateControl.modify(
          USE_ELASTICSEARCH_7: nil,
          USE_ELASTICSEARCH_6: nil,
        ) do
          example.run
        end
      end
      context "when Elasticsearch version is 7.x" do
        let(:version_info) do
          { "version" => { "number" => "7.10.2" } }
        end
        it "returns true" do
          expect(described_class.es7?).to eq(true)
        end
      end

      context "when Elasticsearch version is 6.x" do
        let(:version_info) do
          { "version" => { "number" => "6.8.23" } }
        end
        it "returns false" do
          expect(described_class.es7?).to eq(false)
        end
      end
    end
  end
end
