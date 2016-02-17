require "test_helper"
require "indexer"

describe Indexer::DocumentPreparer do
  describe "#prepared" do
    describe "policy areas migration" do
      it "copies topics to policy areas" do
        doc_hash = {
          "link" => "/some-link",
          "topics" => %w(a b),
        }
        stub_request(:get, "http://contentapi.dev.gov.uk/some-link.json").
          to_return(status: 404, body: "", headers: {})

        updated_doc_hash = Indexer::DocumentPreparer.new("fake_client").prepared(doc_hash, nil, true)

        assert_equal %w(a b), updated_doc_hash["policy_areas"]
      end
    end
  end
end
