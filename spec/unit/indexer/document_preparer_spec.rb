require 'spec_helper'

RSpec.describe Indexer::DocumentPreparer, tags: ['shoulda'] do
  describe "#prepared" do
    it "populates popularities" do
      stub_tagging_lookup

      doc_hash = {
        "link" => "/some-link",
      }

      updated_doc_hash = Indexer::DocumentPreparer.new("fake_client", "fake_index").prepared(
        doc_hash,
        { "/some-link" => 0.5 }, true
      )

      assert_equal 0.5, updated_doc_hash["popularity"]
    end

    it "adds document type groupings" do
      stub_tagging_lookup

      doc_hash = {
        "link" => "/some-link",
        "content_store_document_type" => "detailed_guide",
      }

      updated_doc_hash = Indexer::DocumentPreparer.new("fake_client", "fake_index").prepared(
        doc_hash,
        {},
        true
      )

      assert_equal "guidance", updated_doc_hash["navigation_document_supertype"]
    end
  end
end
