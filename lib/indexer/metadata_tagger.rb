require 'csv'

module Indexer
  class MetadataTagger
    def self.initialise(file_name)
      @metadata = {}

      CSV.foreach(file_name, converters: lambda { |v| v || "" }) do |row|
        base_path = row[0]

        if row[1] == "yes"
          metadata_for_path = create_all_metadata
        else
          metadata_for_path = specific_metadata(row)
        end

        metadata_for_path["appear_in_find_eu_exit_guidance_business_finder"] = "yes"

        @metadata[base_path] = metadata_for_path
      end
    end

    def self.amend_all_metadata
      @metadata.each do |base_path, metadata|
        item_in_search = SearchConfig.instance.content_index.get_document_by_link(base_path)
        if item_in_search
          index_to_update = item_in_search["real_index_name"]
          Indexer::AmendWorker.new.perform(index_to_update, base_path, metadata)
        end
      end
    end

    def self.metadata_for_base_path(base_path)
      @metadata[base_path].to_h
    end

    def self.create_all_metadata
      {
        "sector_business_area" => all_sector_business_area,
        "employ_eu_citizens" => all_employ_eu_citizens,
        "doing_business_in_the_eu" => all_doing_business_in_the_eu,
        "regulations_and_standards" => all_regulations_and_standards,
        "personal_data" => all_personal_data,
        "intellectual_property" => all_intellectual_property,
        "receiving_eu_funding" => all_receiving_eu_funding,
        "public_sector_procurement" => all_public_sector_procurement
      }
    end

    def self.specific_metadata(row)
      {
        "sector_business_area" => row.fetch(2, "").split(","),
        "employ_eu_citizens" => row.fetch(3, "").split(","),
        "doing_business_in_the_eu" => row.fetch(4, "").split(","),
        "regulations_and_standards" => row.fetch(5, "").split(","),
        "personal_data" => row.fetch(6, "").split(","),
        "intellectual_property" => row.fetch(7, "").split(","),
        "receiving_eu_funding" => row.fetch(8, "").split(","),
        "public_sector_procurement" => row.fetch(9, "").split(",")
      }.reject do |_, value|
        value == []
      end
    end

    def self.all_sector_business_area
      [
        "accommodation-restaurants-and-catering-services",
        "aerospace",
        "agriculture",
        "air-transport-aviation",
        "ancillary-services",
        "animal-health",
        "automotive",
        "banking-market-infrastructure",
        "broadcasting",
        "chemicals",
        "computer-services",
        "construction-contracting",
        "education",
        "electricity",
        "electronics",
        "environmental-services",
        "fisheries",
        "food-and-drink",
        "furniture-and-other-manufacturing",
        "gas-markets",
        "goods-sectors-each-0-4-of-gva",
        "imports",
        "imputed-rent",
        "insurance",
        "land-transport-excl-rail",
        "medical-services",
        "motor-trades",
        "network-industries-0-3-of-gva",
        "oil-and-gas-production",
        "other-personal-services",
        "parts-and-machinery",
        "pharmaceuticals",
        "post",
        "professional-and-business-services",
        "public-administration-and-defence",
        "rail",
        "real-estate-excl-imputed-rent",
        "retail",
        "service-sectors-each-1-of-gva",
        "social-work",
        "steel-and-other-metals-commodities",
        "telecoms",
        "textiles-and-clothing",
        "top-ten-trade-partners-by-value",
        "warehousing-and-support-for-transportation",
        "water-transport-maritime-ports",
        "wholesale-excl-motor-vehicles"
      ]
    end

    def self.all_employ_eu_citizens
      %w(yes no dont-know)
    end

    def self.all_doing_business_in_the_eu
      [
        "do-business-in-the-eu",
        "buying",
        "selling",
        "transporting",
        "other-eu",
        "other-rest-of-the-world"
      ]
    end

    def self.all_regulations_and_standards
      %w(products-or-goods)
    end

    def self.all_personal_data
      [
        "processing-personal-data",
        "interacting-with-eea-website",
        "digital-service-provider"
      ]
    end

    def self.all_intellectual_property
      [
        "have-intellectual-property",
        "copyright",
        "trademarks",
        "designs",
        "patents",
        "exhaustion-of-rights"
      ]
    end

    def self.all_receiving_eu_funding
      [
        "horizon-2020",
        "cosme",
        "european-investment-bank-eib",
        "european-structural-fund-esf",
        "eurdf",
        "etcf",
        "esc",
        "ecp",
        "etf"
      ]
    end

    def self.all_public_sector_procurement
      [
        "civil-government-contracts",
        "defence-contracts"
      ]
    end
  end
end
