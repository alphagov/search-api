require 'spec_helper'

RSpec.describe Indexer::MetadataTagger do
  # rubocop:disable RSpec/VerifiedDoubles, RSpec/AnyInstance, RSpec/MessageSpies
  it "amends documents" do
    fixture_file = File.expand_path("fixtures/metadata.json", __dir__)
    base_path = '/foobang'
    test_index_name = 'test-index'

    mock_index = double("index")

    expect_any_instance_of(LegacyClient::IndexForSearch).to receive(:get_document_by_link)
      .and_return('real_index_name' => test_index_name)

    expect(mock_index).to receive(:amend).with(base_path, "aircraft_category" => "big")
    expect_any_instance_of(SearchIndices::SearchServer).to receive(:index)
      .with(test_index_name)
      .and_return(mock_index)

    described_class.amend_indexes_for_file(fixture_file)
  end
  # rubocop:enable RSpec/VerifiedDoubles, RSpec/AnyInstance, RSpec/MessageSpies
end
