require "test_helper"
require "taxonomy_prototype/taxon_finder"

describe TaxonomyPrototype::TaxonFinder do
  describe "find_by(slug:)" do
    before do
      CSV.stubs(:read).returns([
        ["test-taxon-1", "/test/slug/1"],
        ["test-taxon-2 > test-taxon-3", "/test/slug/2"]
      ])
    end

    it "returns a taxon when given a matching slug" do
      File.stubs(:exist?).returns(true)
      taxon = TaxonomyPrototype::TaxonFinder.find_by(slug: "/test/slug/2")
      assert_equal ["test-taxon-2", "test-taxon-3"], taxon
    end

    it "returns nothing given a non-matching slug" do
      File.stubs(:exist?).returns(true)
      taxon = TaxonomyPrototype::TaxonFinder.find_by(slug: "/test/slug/foobar")
      assert_equal nil, taxon
    end

    it "returns nothing if the expected CSV is not present" do
      File.stubs(:exist?).returns(false)
      taxon = TaxonomyPrototype::TaxonFinder.find_by(slug: "/test/slug/2")
      assert_equal nil, taxon
    end
  end
end
