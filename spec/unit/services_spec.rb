require "spec_helper"

RSpec.describe Services do
  describe ".elasticsearch" do
    before do
      allow(OpenSearch::Client).to receive(:new)
    end

    [
      ["http://localhost", "http://localhost:9200"],
      ["http://localhost:9200", "http://localhost:9200"],
      ["https://example.com", "https://example.com:443"],
      ["https://example.com:443", "https://example.com:443"],
    ].each do |input, expected|
      it "Ensures the URL has the correct port when it is #{input}" do
        described_class.elasticsearch(hosts: input)

        expect(OpenSearch::Client).to have_received(:new)
                                           .with(hash_including(hosts: expected))
      end
    end
  end
end
