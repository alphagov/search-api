require "test_helper"
require "taxonomy_prototype/taxon_finder"
require "tempfile"

describe TaxonomyPrototype::TaxonFinder do
  describe "find_by(slug:)" do
    before do
      @temp_taxon_file = Tempfile.new("taxon_finder_test.csv")
      @temp_taxon_file.write("test-taxon-1\t/test/slug/1\ntest-taxon-2 > test-taxon-3\t/test/slug/2\n")
      @temp_taxon_file.close
      ::TaxonomyPrototype::DataDownloader.stubs(:cache_location).returns(@temp_taxon_file.path)
    end

    after do
      @temp_taxon_file.unlink
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
