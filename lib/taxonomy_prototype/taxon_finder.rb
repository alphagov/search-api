require "taxonomy_prototype/data_downloader"

module TaxonomyPrototype
  class TaxonFinder
    def self.find_by(slug:)
      new.find_by(slug)
    end

    def find_by(slug)
      cache_location = ::TaxonomyPrototype::DataDownloader.cache_location
      if File.exist?(cache_location)
        taxonomy_mappings = CSV.read(cache_location)
        matched_mapping = taxonomy_mappings.find { |mapping| mapping.last == slug }
        matched_mapping.first.split(" > ") if matched_mapping
      end
    end
  end
end
