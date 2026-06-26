RSpec.describe ElasticsearchClient do
  describe ".es7?" do
    let(:es_client) { double("Elasticsearch") }
    let(:indices_client) { double("IndicesClient") }
    let(:version_info) { nil }

    after do
      ElasticsearchClient.reload_version
    end

    before do
      allow(Services).to receive(:elasticsearch).and_return(es_client)
      allow(es_client).to receive_messages(index: {}, search: {}, indices: indices_client, info: version_info)
      allow(indices_client).to receive_messages(put_mapping: {})
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
        it "calls 'search' with the right parameters, without including type" do
          described_class.search(index_name: "index", body: { a: :b }, client: es_client)
          expect(es_client).to have_received(:search).with(index: "index",
                                                           body: { a: :b })
        end
        it "calls 'index' with the right parameters, without including type" do
          described_class.index(id: 123, index_name: "index", atts: { a: :b }, params: { c: :d }, client: es_client)
          expect(es_client).to have_received(:index).with(id: 123,
                                                          index: "index",
                                                          body: { a: :b },
                                                          c: :d)
        end
        it "returns mappings without type" do
          expect(described_class.compatible_mappings({ a: :b }))
            .to eq({ "properties" => { a: :b } })
        end
        it "calls 'put_mapping' with the right parameters, without including type" do
          described_class.put_mapping(index_name: "index", mapping: { a: :b }, client: es_client)
          expect(indices_client).to have_received(:put_mapping).with(index: "index",
                                                                     body: { a: :b })
        end
      end

      context "when Elasticsearch version is 6.x" do
        let(:version_info) do
          { "version" => { "number" => "6.8.23" } }
        end
        it "returns false" do
          expect(described_class.es7?).to eq(false)
        end
        it "calls 'search' with the right parameters, including type" do
          described_class.search(index_name: "index", body: { a: :b }, client: es_client)
          expect(es_client).to have_received(:search).with(index: "index",
                                                           body: { a: :b },
                                                           type: "generic-document")
        end
        it "calls 'index' with the right parameters, including type" do
          described_class.index(id: 123, index_name: "index", atts: { a: :b }, params: { c: :d }, client: es_client)
          expect(es_client).to have_received(:index).with(id: 123,
                                                          index: "index",
                                                          body: { a: :b },
                                                          c: :d,
                                                          type: "generic-document")
        end
        it "returns mappings with type" do
          expect(described_class.compatible_mappings({ a: :b }))
            .to eq("generic-document" => { "properties" => { a: :b } })
        end
        it "calls 'put_mapping' with the right parameters, including type" do
          described_class.put_mapping(index_name: "index", mapping: { a: :b }, client: es_client)
          expect(indices_client).to have_received(:put_mapping).with(index: "index",
                                                                     body: { a: :b },
                                                                     type: "generic-document")
        end
      end
    end
  end
end
