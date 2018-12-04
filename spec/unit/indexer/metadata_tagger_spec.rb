require 'spec_helper'

RSpec.describe Indexer::MetadataTagger do
  let(:facet_config_file) { File.expand_path("fixtures/facet_config.yml", __dir__) }
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
      "business_activity" => %w(yes),
      "appear_in_find_eu_exit_guidance_business_finder" => "yes"
    }

    expect(mock_index).to receive(:amend).with(base_path, metadata)
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with(test_index_name)
      .and_return(mock_index)

    described_class.initialise(fixture_file, facet_config_file)
    described_class.amend_all_metadata
  end
  # rubocop:enable RSpec/VerifiedDoubles, RSpec/AnyInstance, RSpec/MessageSpies
end
