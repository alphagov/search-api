require "test_helper"
require "indexer"

describe Indexer::DocumentPreparer do
  describe "#prepared" do
    let(:doc_hash) { {"link" => "some-slug" } }

    before do
      Indexer::TagLookup.stubs(:new).returns(
        OpenStruct.new(prepare_tags: doc_hash)
      )
    end

    describe "alpha taxonomies" do
      it "adds an alpha taxonomy to the doc if a match is found" do
        ::TaxonomyPrototype::TaxonFinder.stubs(:find_by).returns(["taxon-1", "taxon-2"])

        updated_doc_hash = Indexer::DocumentPreparer.new("fake_client").prepared(doc_hash, nil, true)
        assert_equal doc_hash.merge("alpha_taxonomy" => ["taxon-1", "taxon-2"]), updated_doc_hash
      end

      it "does nothing to the doc if no match is found" do
        ::TaxonomyPrototype::TaxonFinder.stubs(:find_by).returns(nil)

        updated_doc_hash = Indexer::DocumentPreparer.new("fake_client").prepared(doc_hash, nil, true)
        assert_equal doc_hash, updated_doc_hash
      end
    end
  end
end
