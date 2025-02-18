require "rspec"

RSpec.describe GovukIndex::MigratedFormats do
  it "does not contain formats with value of :all in both the indexable and non_indexable lists" do
    indexable = described_class.indexable_formats
    non_indexable = described_class.non_indexable_formats

    duplicate_keys = indexable.keys & non_indexable.keys

    duplicate_keys.each do |duplicate_key|
      expect(indexable[duplicate_key]).not_to eq(:all)
      expect(non_indexable[duplicate_key]).not_to eq(:all)
    end
  end

  it "does not contain formats with paths in both the indexable and non_indexable lists" do
    indexable = described_class.indexable_formats
    non_indexable = described_class.non_indexable_formats

    duplicate_keys = indexable.keys & non_indexable.keys
    duplicate_keys.each do |duplicate_key|
      expect(indexable[duplicate_key].to_a & non_indexable[duplicate_key].to_a).to be_empty
    end
  end

  describe "content that has indexable format but non-indexable path" do
    it "returns true if the content is non indexable for a format that is otherwise indexable" do
      non_indexable_path = described_class.non_indexable_path

      expect(non_indexable_path.include?("/help/cookie-details")).to be true
      expect(described_class.non_indexable?("help_page", "/help/cookie-details")).to be true
    end
  end
end
