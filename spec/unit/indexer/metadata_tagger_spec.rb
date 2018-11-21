require 'spec_helper'

RSpec.describe Indexer::MetadataTagger do
  # rubocop:disable RSpec/VerifiedDoubles, RSpec/AnyInstance, RSpec/MessageSpies
  it "amends documents" do
    fixture_file = File.expand_path("fixtures/metadata.csv", __dir__)
    base_path = '/a_base_path'
    test_index_name = 'test-index'

    mock_index = double("index")

    expect_any_instance_of(LegacyClient::IndexForSearch).to receive(:get_document_by_link)
      .and_return('real_index_name' => test_index_name)

    metadata = {
      "sector_business_area" => %w(aerospace agriculture),
      "employ_eu_citizens" => %w(yes),
      "appear_in_find_eu_exit_guidance_business_finder" => "yes"
    }

    expect(mock_index).to receive(:amend).with(base_path, metadata)
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with(test_index_name)
      .and_return(mock_index)

    described_class.amend_indexes_for_file(fixture_file)
  end

  it "amends with everything" do
    # the second field in our csv indicates whether or not our base path should be
    # tagged to every value of every facet. When this field is "yes", we should
    # tag to everything
    fixture_file = File.expand_path("fixtures/metadata_for_all.csv", __dir__)
    test_index_name = 'test-index'
    base_path = '/a_base_path'

    mock_index = double("index")

    expect_any_instance_of(LegacyClient::IndexForSearch).to receive(:get_document_by_link)
      .and_return('real_index_name' => test_index_name)

    metadata = {
      "sector_business_area" => ["accommodation-restaurants-and-catering-services", "aerospace", "agriculture", "air-transport-aviation", "ancillary-services", "animal-health", "automotive", "banking-market-infrastructure", "broadcasting", "chemicals", "computer-services", "construction-contracting", "education", "electricity", "electronics", "environmental-services", "fisheries", "food-and-drink", "furniture-and-other-manufacturing", "gas-markets", "goods-sectors-each-0-4-of-gva", "imports", "imputed-rent", "insurance", "land-transport-excl-rail", "medical-services", "motor-trades", "network-industries-0-3-of-gva", "oil-and-gas-production", "other-personal-services", "parts-and-machinery", "pharmaceuticals", "post", "professional-and-business-services", "public-administration-and-defence", "rail", "real-estate-excl-imputed-rent", "retail", "service-sectors-each-1-of-gva", "social-work", "steel-and-other-metals-commodities", "telecoms", "textiles-and-clothing", "top-ten-trade-partners-by-value", "warehousing-and-support-for-transportation", "water-transport-maritime-ports", "wholesale-excl-motor-vehicles"],
      "employ_eu_citizens" => ["yes", "no", "dont-know"],
      "doing_business_in_the_eu" => ["do-business-in-the-eu", "buying", "selling", "transporting", "other-eu", "other-rest-of-the-world"],
      "regulations_and_standards" => ["products-or-goods"],
      "personal_data" => ["processing-personal-data", "interacting-with-eea-website", "digital-service-provider"],
      "intellectual_property" => ["have-intellectual-property", "copyright", "trademarks", "designs", "patents", "exhaustion-of-rights"],
      "receiving_eu_funding" => ["horizon-2020", "cosme", "european-investment-bank-eib", "european-structural-fund-esf", "eurdf", "etcf", "esc", "ecp", "etf"],
      "public_sector_procurement" => ["civil-government-contracts", "defence-contracts"],
      "appear_in_find_eu_exit_guidance_business_finder" => "yes"
    }

    expect(mock_index).to receive(:amend).with(base_path, metadata)
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with(test_index_name)
      .and_return(mock_index)

    described_class.amend_indexes_for_file(fixture_file)
  end
  # rubocop:enable RSpec/VerifiedDoubles, RSpec/AnyInstance, RSpec/MessageSpies
end
