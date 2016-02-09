require "test_helper"
require "indexer"

describe Indexer::DocumentPreparer do
  describe "#prepared" do
    describe "alpha taxonomies" do
      before do
        Indexer::TagLookup.stubs(:prepare_tags).returns({"link" => "some-slug" })
      end

      it "adds an alpha taxonomy to the doc if a match is found" do
        ::TaxonomyPrototype::TaxonFinder.stubs(:find_by).returns(["taxon-1", "taxon-2"])

        updated_doc_hash = Indexer::DocumentPreparer.new("fake_client").prepared({}, nil, true)

        assert_equal ["taxon-1", "taxon-2"], updated_doc_hash['alpha_taxonomy']
      end

      it "does nothing to the doc if no match is found" do
        ::TaxonomyPrototype::TaxonFinder.stubs(:find_by).returns(nil)

        updated_doc_hash = Indexer::DocumentPreparer.new("fake_client").prepared({}, nil, true)

        assert_nil updated_doc_hash['alpha_taxonomy']
      end
    end
  end
end
