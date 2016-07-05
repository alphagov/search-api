require "test_helper"
require "indexer"

describe Indexer::DocumentPreparer do
  describe "#prepared" do
    it "populates popularities" do
      stub_tagging_lookup

      doc_hash = {
        "link" => "/some-link",
      }

      updated_doc_hash = Indexer::DocumentPreparer.new("fake_client").prepared(
        doc_hash,
        { "/some-link" => 0.5 }, true
      )

      assert_equal 0.5, updated_doc_hash["popularity"]
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
