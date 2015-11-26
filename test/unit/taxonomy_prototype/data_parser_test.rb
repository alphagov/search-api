require "test_helper"
require "taxonomy_prototype/data_parser"

describe TaxonomyPrototype::DataParser do
  describe "write_to(file)" do
    let(:test_output) { StringIO.new }

    it "parses and writes the required data to the file" do
      taxonomy_tsv_data = [
        "mapped to\t"             +  "link",
        "Foo Taxon (Label)\t"     +  "the-foo-slug",
        "Bar Taxon (Label)\t"     +  "the-bar-slug",
        "n/a - not applicable\t"  +  "the-n/a-slug",
      ].join("\n")

      TaxonomyPrototype::DataParser.new(taxonomy_tsv_data).write_to(test_output)

      test_output.rewind
      assert test_output.read, "foo-taxon-label\tthe-foo-slug\nbar-taxon-label\tthe-bar-slug\n"
    end

    it "falls over and dies if the expected columns aren't present" do
      taxonomy_tsv_data = [
        "some random column name\t"  +  "link",
        "Foo Taxon (Label)\t"        +  "the-foo-slug",
      ].join("\n")

      assert_raises ArgumentError do
        TaxonomyPrototype::DataParser.new(taxonomy_tsv_data).write_to(test_output)
      end
    end
  end
end
