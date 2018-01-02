require 'spec_helper'

RSpec.describe Search::ResultSet do
  context "empty result set" do
    before do
      @response = {
        "hits" => {
          "total" => 0,
          "hits" => []
        }
      }
    end

    it "report zero results" do
      expect(described_class.from_elasticsearch(sample_elasticsearch_types, @response).total).to eq(0)
    end

    it "have an empty result set" do
      result_set = described_class.from_elasticsearch(sample_elasticsearch_types, @response)
      expect(result_set.results.size).to eq(0)
    end
  end

  context "single result" do
    before do
      @response = {
        "hits" => {
          "total" => 1,
          "hits" => [
            {
              "_score" => 12,
              "_type" => "contact",
              "_id" => "some_id",
              "_source" => { "foo" => "bar" },
            }
          ]
        }
      }
    end

    it "report one result" do
      expect(described_class.from_elasticsearch(sample_elasticsearch_types, @response).total).to eq(1)
    end

    it "pass the fields to Document.from hash" do
      expected_hash = hash_including("foo" => "bar")
      expect(Document).to receive(:from_hash).with(expected_hash, sample_elasticsearch_types, anything).and_return(:doc)

      result_set = described_class.from_elasticsearch(sample_elasticsearch_types, @response)
      expect(result_set.results).to eq([:doc])
    end

    it "pass the result score to Document.from hash" do
      expect(Document).to receive(:from_hash).with(an_instance_of(Hash), sample_elasticsearch_types, 12).and_return(:doc)

      result_set = described_class.from_elasticsearch(sample_elasticsearch_types, @response)
      expect(result_set.results).to eq([:doc])
    end

    it "populate the document id and type from the metafields" do
      expected_hash = hash_including("_type" => "contact", "_id" => "some_id")
      expect(Document).to receive(:from_hash).with(expected_hash, sample_elasticsearch_types, anything).and_return(:doc)

      result_set = described_class.from_elasticsearch(sample_elasticsearch_types, @response)
      expect(result_set.results).to eq([:doc])
    end
  end
end
