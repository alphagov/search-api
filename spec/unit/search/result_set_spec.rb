require "spec_helper"

RSpec.describe Search::ResultSet do
  context "an empty result set" do
    before do
      @response = {
        "hits" => {
          "total" => 0,
          "hits" => [],
        },
      }
    end

    it "reports zero results" do
      expect(described_class.from_elasticsearch(sample_elasticsearch_types, @response).total).to eq(0)
    end

    it "has a size of zero" do
      result_set = described_class.from_elasticsearch(sample_elasticsearch_types, @response)
      expect(result_set.results.size).to eq(0)
    end
  end

  context "a result set containing a single result" do
    before do
      @response = {
        "hits" => {
          "total" => 1,
          "hits" => [
            {
              "_score" => 12,
              "_type" => "generic-document",
              "_id" => "some_id",
              "_source" => { "document_type" => "contact", "foo" => "bar" },
            }
          ],
        },
      }
    end

    it "reports one result" do
      expect(described_class.from_elasticsearch(sample_elasticsearch_types, @response).total).to eq(1)
    end

    it "passes the fields to Document.from_hash" do
      expected_hash = hash_including("foo" => "bar")
      expect(Document).to receive(:from_hash).with(expected_hash, sample_elasticsearch_types, anything).and_return(:doc)

      result_set = described_class.from_elasticsearch(sample_elasticsearch_types, @response)
      expect(result_set.results).to eq([:doc])
    end

    it "passes the result score to Document.from_hash" do
      expect(Document).to receive(:from_hash).with(an_instance_of(Hash), sample_elasticsearch_types, 12).and_return(:doc)

      result_set = described_class.from_elasticsearch(sample_elasticsearch_types, @response)
      expect(result_set.results).to eq([:doc])
    end

    it "populates the document id and type from the metafields" do
      expected_hash = hash_including("document_type" => "contact", "_id" => "some_id")
      expect(Document).to receive(:from_hash).with(expected_hash, sample_elasticsearch_types, anything).and_return(:doc)

      result_set = described_class.from_elasticsearch(sample_elasticsearch_types, @response)
      expect(result_set.results).to eq([:doc])
    end
  end
end
