require 'rspec'

RSpec.describe GovukIndex::MigratedFormats do
  it 'does not contain formats with value of :all in both the indexable and non_indexable lists' do
    indexable = described_class.indexable_formats
    non_indexable = described_class.non_indexable_formats

    duplicate_keys = indexable.keys & non_indexable.keys

    duplicate_keys.each do |duplicate_key|
      expect(indexable[duplicate_key]).not_to eq(:all)
      expect(non_indexable[duplicate_key]).not_to eq(:all)
    end
  end

  it 'does not contain formats with paths in both the indexable and non_indexable lists' do
    indexable = described_class.indexable_formats
    non_indexable = described_class.non_indexable_formats

    duplicate_keys = indexable.keys & non_indexable.keys

    duplicate_keys.each do |duplicate_key|
      expect(indexable[duplicate_key] & non_indexable[duplicate_key]).to be_empty
    end
  end
end
