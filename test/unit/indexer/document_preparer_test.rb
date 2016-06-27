require "test_helper"
require "indexer"

describe Indexer::DocumentPreparer do
  describe "#prepared" do
    describe "policy areas migration" do
      it "copies topics to policy areas" do
        stub_tagging_lookup

        doc_hash = { "link" => "/some-link", "topics" => %w(a b) }
        updated_doc_hash = Indexer::DocumentPreparer.new("fake_client").prepared(doc_hash, nil, true)

        assert_equal %w(a b), updated_doc_hash["policy_areas"]
      end
    end

    it "warns via Airbake if the doc contains any links we no longer expect" do
      stub_tagging_lookup
      doc_hash = {
        "link" => "/some-link",
        "specialist_sectors" => %w(foo bar)
      }

      Airbrake.expects(:notify_or_ignore).with(
        Indexer::DocumentPreparer::UnexpectedLinksError.new, parameters: doc_hash
      )
      Indexer::DocumentPreparer.new("fake_client").prepared(doc_hash, nil, true)
    end
  end
end
